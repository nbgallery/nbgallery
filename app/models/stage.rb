# Stage model
class Stage < ActiveRecord::Base
  belongs_to :user

  validates :uuid, :user, presence: true
  validates :uuid, uniqueness: { case_sensitive: false }
  validates :uuid, uuid: true

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
    File.read(filename, encoding: 'UTF-8') if File.exist?(filename)
  end

  # Set new content in file cache
  def content=(content)
    File.write(filename, content)
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
