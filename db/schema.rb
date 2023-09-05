# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_04_07_125703) do

  create_table "change_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "reqid", null: false
    t.integer "requestor_id", null: false
    t.integer "notebook_id", null: false
    t.string "status", null: false
    t.text "requestor_comment"
    t.text "owner_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commit_message"
    t.integer "reviewer_id"
    t.index ["notebook_id"], name: "fk_rails_87d03cd145"
    t.index ["reqid"], name: "index_change_requests_on_reqid", unique: true
    t.index ["requestor_id"], name: "fk_rails_a4b1b45763"
    t.index ["status"], name: "index_change_requests_on_status"
  end

  create_table "clicks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "org"
    t.string "action", null: false
    t.integer "notebook_id"
    t.string "tracking"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook_id"], name: "fk_rails_4dac87767f"
    t.index ["org"], name: "index_clicks_on_action"
    t.index ["org"], name: "index_clicks_on_org"
    t.index ["user_id"], name: "fk_rails_18f7781f15"
  end

  create_table "code_cells", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.integer "cell_number"
    t.string "md5"
    t.text "ssdeep"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["md5"], name: "index_code_cells_on_md5"
    t.index ["notebook_id"], name: "fk_rails_185a49c378"
  end

  create_table "commontator_comments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "creator_type"
    t.integer "creator_id"
    t.string "editor_type"
    t.integer "editor_id"
    t.integer "thread_id", null: false
    t.text "body", null: false
    t.datetime "deleted_at"
    t.integer "cached_votes_up", default: 0
    t.integer "cached_votes_down", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["cached_votes_down"], name: "index_commontator_comments_on_cached_votes_down"
    t.index ["cached_votes_up"], name: "index_commontator_comments_on_cached_votes_up"
    t.index ["creator_id", "creator_type", "thread_id"], name: "index_commontator_comments_on_c_id_and_c_type_and_t_id"
    t.index ["thread_id", "created_at"], name: "index_commontator_comments_on_thread_id_and_created_at"
  end

  create_table "commontator_subscriptions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "subscriber_type", null: false
    t.integer "subscriber_id", null: false
    t.integer "thread_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["subscriber_id", "subscriber_type", "thread_id"], name: "index_commontator_subscriptions_on_s_id_and_s_type_and_t_id", unique: true
    t.index ["thread_id"], name: "index_commontator_subscriptions_on_thread_id"
  end

  create_table "commontator_threads", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "commontable_type"
    t.integer "commontable_id"
    t.datetime "closed_at"
    t.string "closer_type"
    t.integer "closer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["commontable_id", "commontable_type"], name: "index_commontator_threads_on_c_id_and_c_type", unique: true
  end

  create_table "deprecated_notebooks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id"
    t.integer "deprecater_user_id"
    t.boolean "disable_usage"
    t.text "reasoning"
    t.text "alternate_notebook_ids"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "environments", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "url"
    t.boolean "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_interface"
    t.index ["user_id"], name: "fk_rails_37f7c42db2"
  end

  create_table "execution_histories", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "notebook_id", null: false
    t.boolean "known_cell"
    t.boolean "unknown_cell"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "day"
    t.index ["day"], name: "index_execution_histories_on_day"
    t.index ["notebook_id"], name: "fk_rails_9fa82906e9"
    t.index ["user_id", "notebook_id", "day"], name: "index_execution_histories_on_user_id_and_notebook_id_and_day", unique: true
  end

  create_table "executions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "code_cell_id", null: false
    t.boolean "success"
    t.float "runtime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["code_cell_id"], name: "fk_rails_3857909a04"
    t.index ["user_id"], name: "fk_rails_b9357380e9"
  end

  create_table "feedbacks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.integer "notebook_id", null: false
    t.boolean "ran"
    t.boolean "worked"
    t.text "broken_feedback"
    t.text "general_feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook_id"], name: "fk_rails_ce692a7059"
    t.index ["user_id"], name: "fk_rails_c57bb6cf28"
  end

  create_table "groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "gid", null: false
    t.string "name", null: false
    t.text "description", size: :medium
    t.string "url"
    t.integer "landing_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gid"], name: "index_groups_on_gid", unique: true
    t.index ["landing_id"], name: "fk_rails_f35b091940"
  end

  create_table "groups_users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.boolean "creator"
    t.boolean "owner"
    t.boolean "editor"
    t.index ["group_id", "user_id"], name: "index_groups_users_on_group_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_8546c71994"
  end

  create_table "identities", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "uid"
    t.string "provider"
    t.integer "user_id"
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "notebook_dailies", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.date "day"
    t.integer "unique_users", default: 0
    t.integer "unique_executors", default: 0
    t.float "daily_score", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day"], name: "index_notebook_dailies_on_day"
    t.index ["notebook_id"], name: "index_notebook_dailies_on_notebook_id"
  end

  create_table "notebook_files", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.text "content", size: :medium, null: false
    t.string "save_type", null: false
    t.string "uuid", null: false
    t.integer "revision_id"
    t.integer "change_request_id"
    t.integer "stage_id"
    t.integer "notebook_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["change_request_id"], name: "fk_rails_db17b599fb"
    t.index ["notebook_id"], name: "fk_rails_2b60b86873"
    t.index ["revision_id"], name: "fk_rails_450e785378"
    t.index ["stage_id"], name: "fk_rails_6c3c57487e"
    t.index ["uuid"], name: "index_notebook_files_on_uuid", length: 190
  end

  create_table "notebook_similarities", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.integer "other_notebook_id", null: false
    t.float "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook_id", "other_notebook_id"], name: "index_notebook_similarities_on_notebook_id_and_other_notebook_id", unique: true
    t.index ["other_notebook_id"], name: "fk_rails_6440fa59c2"
  end

  create_table "notebook_summaries", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.integer "views", default: 0
    t.integer "unique_views", default: 0
    t.integer "downloads", default: 0
    t.integer "unique_downloads", default: 0
    t.integer "runs", default: 0
    t.integer "unique_runs", default: 0
    t.integer "stars", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "health"
    t.float "trendiness"
    t.float "previous_health"
    t.string "health_description"
    t.float "review"
    t.string "review_description"
    t.index ["health"], name: "index_notebook_summaries_on_health"
    t.index ["notebook_id"], name: "index_notebook_summaries_on_notebook_id", unique: true
    t.index ["review"], name: "index_notebook_summaries_on_review"
    t.index ["trendiness"], name: "index_notebook_summaries_on_trendiness"
  end

  create_table "notebooks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "title", null: false
    t.text "description", size: :medium, null: false
    t.boolean "public", null: false
    t.string "lang"
    t.string "lang_version"
    t.string "commit_id"
    t.datetime "content_updated_at"
    t.string "owner_type"
    t.integer "owner_id"
    t.integer "creator_id"
    t.integer "updater_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "deprecated", default: false
    t.string "parent_uuid"
    t.index ["creator_id"], name: "fk_rails_3af8e2efd7"
    t.index ["deprecated"], name: "index_notebooks_on_deprecated"
    t.index ["lang"], name: "index_notebooks_on_lang"
    t.index ["owner_type", "owner_id"], name: "index_notebooks_on_owner_type_and_owner_id"
    t.index ["parent_uuid"], name: "index_notebooks_on_parent_uuid"
    t.index ["title"], name: "index_notebooks_on_title"
    t.index ["updater_id"], name: "fk_rails_baf035bcbf"
    t.index ["uuid"], name: "index_notebooks_on_uuid"
  end

  create_table "oauth_access_grants", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "fk_rails_b4b53e07b8"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "fk_rails_732cb83ab7"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "preferences", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "smart_indent"
    t.boolean "auto_close_brackets"
    t.boolean "easy_buttons"
    t.integer "indent_unit"
    t.integer "tab_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "lab_preferences"
    t.index ["user_id"], name: "fk_rails_87f1c9c7bd"
  end

  create_table "recommended_reviewers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "review_id", null: false
    t.integer "user_id", null: false
    t.float "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "fk_rails_1384b06cf7"
    t.index ["user_id"], name: "fk_rails_d36d2d95c0"
  end

  create_table "resources", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "href"
    t.string "title"
    t.integer "notebook_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook_id"], name: "index_resources_on_notebook_id"
    t.index ["user_id"], name: "index_resources_on_user_id"
  end

  create_table "reviews", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.integer "revision_id"
    t.integer "reviewer_id"
    t.string "revtype", null: false
    t.string "status", null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook_id"], name: "fk_rails_8efab41d7d"
    t.index ["reviewer_id"], name: "fk_rails_007031d9cb"
    t.index ["revision_id"], name: "fk_rails_8204389e51"
    t.index ["revtype"], name: "index_reviews_on_revtype"
    t.index ["status"], name: "index_reviews_on_status"
  end

  create_table "revisions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.integer "notebook_id", null: false
    t.boolean "public"
    t.string "commit_id"
    t.string "revtype"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commit_message"
    t.integer "change_request_id"
    t.string "friendly_label", limit: 16
    t.index ["notebook_id"], name: "fk_rails_55cc590dc1"
    t.index ["user_id"], name: "fk_rails_47677c2e75"
  end

  create_table "shares", id: false, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.integer "user_id", null: false
    t.index ["notebook_id"], name: "fk_rails_0020a7326d"
    t.index ["user_id", "notebook_id"], name: "index_shares_on_user_id_and_notebook_id", unique: true
  end

  create_table "site_warnings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.string "level", null: false
    t.text "message", null: false
    t.datetime "expires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "fk_rails_bec75fa2b8"
  end

  create_table "stages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "uuid", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "fk_rails_b07f32c2f3"
    t.index ["uuid"], name: "index_stages_on_uuid", unique: true
  end

  create_table "stars", id: false, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "notebook_id", null: false
    t.index ["notebook_id", "user_id"], name: "index_stars_on_notebook_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_510b95ed0a"
  end

  create_table "subscriptions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "sub_type", null: false
    t.integer "sub_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "suggested_groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "fk_rails_a330b06365"
    t.index ["user_id"], name: "fk_rails_35ca5b5b63"
  end

  create_table "suggested_notebooks", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "notebook_id", null: false
    t.text "reason"
    t.float "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type"
    t.integer "source_id"
    t.index ["notebook_id"], name: "fk_rails_84bb081639"
    t.index ["reason"], name: "index_suggested_notebooks_on_reason", length: 32
    t.index ["source_type", "source_id"], name: "index_suggested_notebooks_on_source_type_and_source_id"
    t.index ["user_id"], name: "fk_rails_a3a86893f2"
  end

  create_table "suggested_tags", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "tag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "fk_rails_8b4f9af37c"
  end

  create_table "tags", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.string "tag", null: false
    t.integer "notebook_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook_id"], name: "fk_rails_670ed3316c"
    t.index ["tag"], name: "index_tags_on_tag"
    t.index ["user_id"], name: "fk_rails_e689f6d0cc"
  end

  create_table "user_preferences", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.string "theme"
    t.integer "timezone"
    t.boolean "high_contrast"
    t.boolean "larger_text"
    t.boolean "ultimate_accessibility_mode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "full_cells"
    t.boolean "disable_row_numbers", default: false
  end

  create_table "user_similarities", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "other_user_id", null: false
    t.float "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["other_user_id"], name: "fk_rails_b390993b6f"
    t.index ["user_id", "other_user_id"], name: "index_user_similarities_on_user_id_and_other_user_id", unique: true
  end

  create_table "user_summaries", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id", null: false
    t.float "user_rep_raw", default: 0.0
    t.float "user_rep_pct", default: 0.0
    t.float "author_rep_raw", default: 0.0
    t.float "author_rep_pct", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_summaries_on_user_id", unique: true
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "email"
    t.string "password"
    t.string "first_name"
    t.string "last_name"
    t.string "org"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "user_name"
    t.boolean "approved"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_name"], name: "index_users_on_user_name"
  end

  create_table "users_also_views", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.integer "other_notebook_id", null: false
    t.float "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook_id", "other_notebook_id"], name: "index_users_also_views_on_notebook_id_and_other_notebook_id", unique: true
    t.index ["other_notebook_id"], name: "fk_rails_e8f6d21371"
  end

  create_table "votes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "votable_type"
    t.integer "votable_id"
    t.string "voter_type"
    t.integer "voter_id"
    t.boolean "vote_flag"
    t.string "vote_scope"
    t.integer "vote_weight"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope"
    t.index ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope"
  end

  add_foreign_key "change_requests", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "change_requests", "users", column: "requestor_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "clicks", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "clicks", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "code_cells", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "environments", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "execution_histories", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "execution_histories", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "executions", "code_cells", on_update: :cascade, on_delete: :cascade
  add_foreign_key "executions", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "feedbacks", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "feedbacks", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "groups", "notebooks", column: "landing_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "groups_users", "groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "groups_users", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "notebook_dailies", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "notebook_files", "change_requests"
  add_foreign_key "notebook_files", "notebooks"
  add_foreign_key "notebook_files", "revisions"
  add_foreign_key "notebook_files", "stages"
  add_foreign_key "notebook_similarities", "notebooks", column: "other_notebook_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "notebook_similarities", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "notebook_summaries", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "notebooks", "users", column: "creator_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "notebooks", "users", column: "updater_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "preferences", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "recommended_reviewers", "reviews", on_update: :cascade, on_delete: :cascade
  add_foreign_key "recommended_reviewers", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "resources", "notebooks"
  add_foreign_key "resources", "users"
  add_foreign_key "reviews", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "reviews", "revisions", on_update: :cascade, on_delete: :cascade
  add_foreign_key "reviews", "users", column: "reviewer_id", on_update: :nullify, on_delete: :nullify
  add_foreign_key "revisions", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "revisions", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "shares", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "shares", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "site_warnings", "users", on_update: :cascade, on_delete: :nullify
  add_foreign_key "stages", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "stars", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "stars", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "suggested_groups", "groups", on_update: :cascade, on_delete: :cascade
  add_foreign_key "suggested_groups", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "suggested_notebooks", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "suggested_notebooks", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "suggested_tags", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tags", "notebooks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tags", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_similarities", "users", column: "other_user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_similarities", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_summaries", "users", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users_also_views", "notebooks", column: "other_notebook_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users_also_views", "notebooks", on_update: :cascade, on_delete: :cascade
end
