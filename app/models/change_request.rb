# Change request model
class ChangeRequest < ActiveRecord::Base
  belongs_to :requestor, class_name: 'User', inverse_of: 'change_requests'
  belongs_to :notebook

  if GalleryConfig.storage.database_notebooks
    has_one :notebook_file, dependent: :destroy
    after_save { |change_request| change_request.link_notebook_file }
  end

  validates :terms_of_service, acceptance: { accept: 'yes' }
  validates :reqid, :requestor, :notebook, :status, presence: true
  validates :reqid, uniqueness: { case_sensitive: false }
  validates :reqid, uuid: true

  after_destroy :remove_proposed_content

  include ExtendableModel

  # Must be in pending state to do anything
  class NotPending < RuntimeError
  end

  # Exception for uploads with bad parameters
  class BadUpload < RuntimeError
    attr_reader :errors

    def initialize(message, errors=nil)
      super(message)
      @errors = errors
    end

    def message
      msg = super
      if errors
        msg + ': ' + errors.full_messages.join('; ')
      else
        msg
      end
    end
  end


  #########################################################
  # Raw content methods
  #########################################################

  # Location on disk
  def filename
    File.join(GalleryConfig.directories.change_requests, "#{reqid}.ipynb")
  end

  # The proposed raw content from the file cache
  def proposed_content
    if GalleryConfig.storage.database_notebooks
      notebookFile = NotebookFile.where(save_type: "change_request", uuid: reqid, change_request_id: id).first
      notebookFile.content
    else
      File.read(filename, encoding: 'UTF-8')
    end
  end

  # The proposed JSON-parsed notebook from the file cache
  def proposed_notebook
    JupyterNotebook.new(proposed_content)
  end

  # Set content in file cache
  def proposed_content=(content)
    if GalleryConfig.storage.database_notebooks
      notebookFile = NotebookFile.find_or_initialize_by(save_type: "change_request", uuid: reqid)
      notebookFile.change_request_id = id
      notebookFile.content = content
      notebookFile.save
    else
      File.write(filename, content)
    end
  end

  # Save notebook in file cache
  def proposed_notebook=(notebook_obj)
    self.proposed_content = notebook_obj.to_json
  end

  # Removed proposed content from file cache
  def remove_proposed_content
    if GalleryConfig.storage.database_notebooks
      NotebookFile.where(save_type: "change_request", uuid: reqid, change_request_id: id).destroy_all
    else
      File.unlink(filename) if File.exist?(filename)
    end
  end

  # The current raw content from the file cache
  def current_content
    notebook.content
  end

  # The current JSON-parsed notebook from the file cache
  def current_notebook
    notebook.notebook
  end

  # Ensure the NotebookFile entry is linked to the stage after the stage_id is generated
  def link_notebook_file
    notebookFile = NotebookFile.where(save_type:"change_request",uuid: reqid).first
    if notebookFile
      notebookFile.change_request_id = id
      notebookFile.save
    end
  end

  #########################################################
  # Age off
  #########################################################

  def self.age_off
    # Remove all old canceled requests
    ChangeRequest.where("status = 'canceled' AND updated_at < ?", 7.days.ago).destroy_all

    # Remove notebook content from all old approved requests
    ChangeRequest.where("status = 'accepted' AND updated_at < ?", 7.days.ago).each do | change_request |
      change_request.remove_proposed_content
    end

  end


  #########################################################
  # Diffs
  #########################################################

  def diff_css
    GalleryLib::Diff.css
  end

  def diff_inline
    current_text = current_notebook.text_for_diff
    proposed_text = proposed_notebook.text_for_diff
    GalleryLib::Diff.inline(current_text, proposed_text)
  end

  def diff_split
    current_text = current_notebook.text_for_diff
    proposed_text = proposed_notebook.text_for_diff
    GalleryLib::Diff.split(current_text, proposed_text)
  end
end
