# Stage model
class Stage < ActiveRecord::Base
  belongs_to :user

  validates :uuid, :user, presence: true
  validates :uuid, uniqueness: { case_sensitive: false }
  validates :uuid, uuid: true
  if GalleryConfig.storage.database_notebooks
    has_one :notebook_file, dependent: :destroy
    after_save { |stage| stage.link_notebook_file }
  end

  after_destroy :remove_content

  #########################################################
  # Raw content methods
  #########################################################

  # Location on disk
  def filename
    File.join(GalleryConfig.directories.staging, "#{uuid}.ipynb")
  end

  # The raw content from the file cache
  def content
    if GalleryConfig.storage.database_notebooks
      notebookFile = NotebookFile.where(save_type: "stage", uuid: uuid).first
      notebookFile.content if !notebookFile.nil?
    else
      File.read(filename, encoding: 'UTF-8') if File.exist?(filename)
    end
  end

  # Set new content in file cache
  def content=(content)
    if GalleryConfig.storage.database_notebooks
      notebookFile = NotebookFile.find_or_initialize_by(save_type: "stage", uuid: uuid)
      notebookFile.stage_id = id
      notebookFile.content = content
      notebookFile.save
    else
      File.write(filename, content)
    end
  end

  # Ensure the NotebookFile entry is linked to the stage after the stage_id is generated
  def link_notebook_file
    notebookFile = NotebookFile.where(save_type:"stage",uuid: uuid).first
    if !notebookFile.nil?
      notebookFile.stage_id = id
      notebookFile.save
    end
  end

  # The JSON-parsed notebook from the file cache
  def notebook
    JupyterNotebook.new(content)
  end

  # Remove the cached file
  def remove_content
    File.unlink(filename) if File.exist?(filename)
  end

  #########################################################
  # Age off
  #########################################################
  def self.age_off
    # Stages can get orphaned if the upload isn't completed.
    # The upload should happen shortly after the stage, so
    # remove old ones after a few hours.
    Stage.where('updated_at < ?', 6.hours.ago).destroy_all
  end
end
