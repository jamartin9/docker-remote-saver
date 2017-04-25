#!/usr/bin/env ruby
#
# Cobbled together endpoint for gettings tars.
# Author: Jam
# TODO: multiple files in single tar.gz
#       Repo URL/Connection information
#       UI
#       Tests
require 'sinatra'
require 'docker-api'
set :environment, :production
set :port, 8080
set :dump_errors, false
# concurrency lock
#set :lock, true
# defaults to views
#set :views, '/var/www/views/'
# enabled by default when public directory exists
set :static, false
#set :public_folder, '/var/www'
get '/?:name?/?' do
    # validate name or return help page
    name = params['name']
    if name.to_s.empty? 
        send_file File.join('help.html')
        return
    end
    # validate version or turn into latest
    version = params['version']
    if version.to_s.empty? 
        version = 'latest'
    end
    # default to docker.io
    user = params['user']
    if user.to_s.empty? 
        user = 'docker.io'
        image_name = name + ':' + version
    else
        # set to user supplied image name
        image_name = user + '/' + name + ':' + version
    end
    # name vars
    tar_name = user + '_' + name + '_' + version + '.tar'
    tar_gzip_name = tar_name + ".gz"
    # check if the gzip exists yet 
    if !File.file?(tar_gzip_name)
        # Search image and return error not found page upon fails
        if !Docker::Image.exist?(image_name)
            begin
                Docker::Image.create('fromImage' => image_name)
            rescue
                send_file File.join('error.html')
                return
            end
        end
        # Save the image off to tar
        #names = %w( my_image1 my_image2:not_latest )
        Docker::Image.save(image_name, tar_name)
        # gzip tar with stamps
        Zlib::GzipWriter.open(tar_gzip_name) do |gz|
            gz.mtime = File.mtime(tar_name)
            gz.orig_name = tar_name
            gz.write IO.binread(tar_name)
            gz.close
        end
        # cleanup tar
        File.delete(tar_name)
    end
    headers['Content-Disposition'] = "attachment"
    # send gzipped file
    send_file File.join(tar_gzip_name)
end