# frozen_string_literal: true

desc 'Updates the local build directory from S3'
task :download do
  sh "aws s3 sync s3://#{ENV.fetch('BUCKET')} build --exact-timestamps"
end

desc 'Deploys the website'
task deploy: %i[download build] do
  bucket = ENV.fetch('BUCKET')
  dist = ENV.fetch('DISTRIBUTION_ID')

  sh "aws s3 sync build s3://#{bucket} --acl=public-read --delete " \
    '--cache-control max-age=86400 --exact-timestamps'

  sh "aws cloudfront create-invalidation --distribution-id #{dist} --paths '/*'"
end
