# frozen_string_literal: true

rule '.svg' => '.dot' do |task|
  sh "dot -T svg -o #{task.name} #{task.source}"
end

task images: %w[
  source/images/september-2019-progress-report/serial.svg
  source/images/september-2019-progress-report/parallel.svg
  source/images/september-2019-progress-report/modules.svg
  source/images/october-2019-progress-report/unreachable_young_object.svg
]
