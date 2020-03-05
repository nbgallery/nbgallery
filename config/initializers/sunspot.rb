require 'rake'

if defined?(Rails::Server) && Rails.env.development? && Rails.configuration.run_solr
  Rails.application.load_tasks

  Rake.application.invoke_task 'sunspot:solr:start'

  at_exit do
    Rake.application.invoke_task 'sunspot:solr:stop'
  end
end
