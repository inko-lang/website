# frozen_string_literal: true

require 'rake/clean'
require 'time'

CLEAN.include('build')

Dir.glob(File.expand_path('task/*.rake', __dir__)) { |task| import task }

task default: :server
