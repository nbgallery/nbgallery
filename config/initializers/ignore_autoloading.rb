Rails.autoloaders.each do |autoloader|
  # ignore directories not associated with created Classes/Modules (i.e. migrations, unit tests, cron jobs)
  Dir.glob("#{Rails.root}/**/{cronic.d,migrate,test}").each do |dir|
    autoloader.ignore(dir)
  end

  # add any other custom autoloading ignoraces below
end