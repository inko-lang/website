# frozen_string_literal: true

require 'http'
require 'json'
require 'mime/types'
require 'mini_magick'
require 'set'
require 'yaml'
require 'pathname'
require 'graphql/client'
require 'graphql/client/http'

require_relative 'sponsors/image'
require_relative 'sponsors/image_pruner'
require_relative 'sponsors/github'
