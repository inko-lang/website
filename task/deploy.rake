# frozen_string_literal: true

desc 'Deploys the website'
task deploy: [:build] do
  sh 'bundle exec middleman s3_sync'
  sh "aws cloudfront create-invalidation --distribution-id #{ENV['DISTRIBUTION_ID']} --paths '/*'"
end
