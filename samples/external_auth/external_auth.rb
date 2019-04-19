Devise.setup do |config|
  config.warden do |manager|
    manager.strategies.add(:external, Devise::Strategies::ExternalAuth)
    manager.default_strategies(scope: :user).unshift(:external)
  end
end
