Rails.application.config.searchable_fields = {
  "tags:" => {
    query: ->(words) { Tag.where('LOWER(tag) LIKE ?', "%#{words.downcase}%").distinct.limit(5).pluck(:tag) }
  },
  "user:" => {
    query: ->(words) { User.where('LOWER(user_name) LIKE ?', "%#{words.downcase}%").distinct.limit(5).pluck(:user_name) }
  },
  "creator:" => {
    query: ->(words) { User.where('LOWER(user_name) LIKE ?', "%#{words.downcase}%").distinct.limit(5).pluck(:user_name) }
  },
  "updater:" => {
    query: ->(words) { User.where('LOWER(user_name) LIKE ?', "%#{words.downcase}%").distinct.limit(5).pluck(:user_name) }
  },
  "owner:" => {
    query: ->(words) { User.where('LOWER(user_name) LIKE ?', "%#{words.downcase}%").distinct.limit(5).pluck(:user_name) }
  },
  "title:" => {
    query: ->(words, user) { 
        if user.admin?
          Notebook.where('LOWER(title) LIKE ?', "%#{words.downcase}%").distinct.limit(5).pluck(:title)  
        else
          Notebook.where('LOWER(title) like ?', "%#{words.downcase}%").where("public=True").distinct.limit(5).pluck(:title)
        end
    },
    full_text: ->(query, user) { 
        if user.admin?
          Notebook.where('LOWER(title) LIKE ?', "%#{query.downcase}%").distinct.limit(5).pluck(:title)
        else
          Notebook.where('LOWER(title) like ?', "%#{query.downcase}%").where("public=True").distinct.limit(5).pluck(:title)
        end
    }
  },
  "lang:" => {
    query: ->(words) { Notebook.where('LOWER(lang) like ?', "%#{words.downcase}%").distinct.limit(5).pluck(:lang) }
  },
  "description:" => {
    query: ->(words) { Notebook.where('LOWER(description) LIKE ?', "%#{words.downcase}%").distinct.limit(5).pluck(:description) },
    full_text: ->(query) { Notebook.where('LOWER(description) LIKE ?', "%#{query.downcase}%").distinct.limit(5).pluck(:description) }
  }
  # TODO: Add package, updated_at, and created_at fields
}.freeze