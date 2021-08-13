json.extract!(
  feedback,
  :ran,
  :worked,
  :broken_feedback,
  :general_feedback,
  :updated_at
)
json.user = feedback.user.user_name
