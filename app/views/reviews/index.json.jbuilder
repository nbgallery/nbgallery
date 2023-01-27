json.array!(@reviews) do | review |
    next if (!review.notebook.public? && !(@user.admin? || @user.can_edit?(review.notebook)))
    json.extract! review, :id, :revision_id, :updated_at, :created_at, :status, :comments
    json.url review_url(review)
    if review.reviewer
        json.reviewer do 
            json.url user_url(review.reviewer, format: :json)
            json.user_name review.reviewer.user_name
        end 
    end

    json.notebook(review.notebook, partial: 'application/notebook_json', as: :notebook)
    json.review_type GalleryConfig.reviews[review.revtype].label
end