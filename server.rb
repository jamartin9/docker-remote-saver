#!/usr/bin/env ruby
#
# Cobbled together endpoint for gettings tars.
# Author: Jam
# TODO: multiple files in single tar.gz
#       Repo URL/Connection information
#       UI
require 'docker-api'
require 'sinatra'
require 'json'

# config parsing
def parse_port
  '9001' if ENV['PORT'].to_s.empty?
end

# config
set :environment, :production
set :port, parse_port
set :dump_errors, false
set :static, false
# concurrency lock
# set :lock, true
# defaults to views
# set :views, '/var/www/views/'
# enabled by default when public directory exists
# set :public_folder, '/var/www'

# creates downloable gziped docker tar
def create_downloadable(image_name, tar_name, tar_gzip_name)
  # Save the image off to tar
  # names = %w( my_image1 my_image2:not_latest )
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

# version config to endpoint
def check_version(version)
  return 'latest' if version.to_s.empty?
end

# user config to endpoint
def check_user(user)
  if user.to_s.empty?
    'docker.io'
  else
    user
  end
end

# docker image name creation
def create_image_name(user, name, version)
  if 'docker.io' == user
    name + ':' + version
  else
    # set to user supplied image name
    user + '/' + name + ':' + version
  end
end

# singular rest endpoint
# returns help without required path
# returns error on not found/disk full
# returns download of docker image as tar.gz on success
# optional params: version and user
get '/?:name?/?' do
  # validate name or return help page
  name = params['name']
  if name.to_s.empty?
    send_file File.join('help.html')
    return
  end
  # validate version or turn into latest
  version = check_version(params['version'])
  # default to docker.io
  user = check_user(params['user'])
  # name vars
  image_name = create_image_name(user, name, version)
  tar_name = user + '_' + name + '_' + version + '.tar'
  tar_gzip_name = tar_name + '.gz'
  # check if the gzip exists yet
  unless File.file?(tar_gzip_name)
    # Search image and return error not found page upon fails
    unless Docker::Image.exist?(image_name)
      begin
        Docker::Image.create('fromImage' => image_name)
      rescue
        send_file File.join('error.html')
        return
      end
    end
    create_downloadable(image_name, tar_name, tar_gzip_name)
  end
  headers['Content-Disposition'] = 'attachment'
  # send gzipped file
  send_file File.join(tar_gzip_name)
end
