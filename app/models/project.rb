# encoding: utf-8
#
#  = Project Model
#
#  A Project is used to encapsulate a collaboration effort to write species
#  descriptions.  Technically, a Project is just defined as a UserGroup of
#  members and a UserGroup of admins, which together own a collection of draft
#  Name Descriptions.
#
#  == Attributes
#
#  id::             Locally unique numerical id, starting at 1.
#  sync_id::        Globally unique alphanumeric id, used to sync with remote servers.
#  created_at::     Date/time it was first created.
#  updated_at::     Date/time it was last updated.
#  user::           User that created it.
#  admin_group::    UserGroup of admins.
#  user_group::     UserGroup of members.
#  title::          Title string.
#  summary::        Summary of purpose.
#
#  == Methods
#
#  is_member?::     Is a given User a member of this Project?
#  is_admin?::      Is a given User an admin for this Project?
#  text_name::      Alias for +title+ for debugging.
#  Proj.has_edit_permission?:: Check if User has permission to edit an Observation/Image/etc.
#
#  ==== Logging
#  log_create::        Log creation.
#  log_update::        Log update.
#  log_destroy::       Log destruction.
#  log_add_member::    Log addition of new member.
#  log_remove_member:: Log removal of member.
#  log_add_admin::     Log addition of new admin.
#  log_remove_admin::  Log removal of admin.
#
#  ==== Callbacks
#  orphan_drafts::     Orphan draft descriptions whe destroyed.
#
################################################################################

class Project < AbstractModel
  belongs_to :admin_group, :class_name => "UserGroup", :foreign_key => "admin_group_id"
  belongs_to :rss_log
  belongs_to :user
  belongs_to :user_group

  has_many :comments,  :as => :target, :dependent => :destroy
  has_many :interests, :as => :target, :dependent => :destroy

  has_and_belongs_to_many :images
  has_and_belongs_to_many :observations
  has_and_belongs_to_many :species_lists

  before_destroy :orphan_drafts

  # Various debugging things require all models respond to +text_name+.  Just
  # returns +title+.
  def text_name
    title.to_s
  end

  # Same as +text_name+ but with id tacked on to make unique.
  def unique_text_name
    text_name + " (#{id || '?'})"
  end

  # Need these to be compatible with Comment.
  alias format_name text_name
  alias unique_format_name unique_text_name

  # Is +user+ a member of this Project?
  def is_member?(user)
    user and (self.user_group.users.member?(user) or user.admin)
  end

  # Is +user+ an admin for this Project?
  def is_admin?(user)
    user and (self.admin_group.users.member?(user) or user.admin)
  end

  # Check if user has permission to edit a given object.
  def self.has_edit_permission?(obj, user)
    result = false
    if user
      if user.id == obj.user_id
        result = true
      elsif !obj.projects.empty?
        # group_ids = user.user_groups_singular_ids # Rails 3 only
        group_ids = user.user_groups.map(&:id)
        for project in obj.projects
          if group_ids.member?(project.user_group_id)
            result = true
            break
          end
        end
      end
    end
    return result
  end

  def add_images(imgs)
    imgs.each {|x| add_image(x)}
  end

  def remove_images(imgs)
    imgs.each {|x| remove_image(x)}
  end

  def add_observations(imgs)
    imgs.each {|x| add_observation(x)}
  end

  def remove_observations(imgs)
    imgs.each {|x| remove_observation(x)}
  end

  def add_species_lists(imgs)
    imgs.each {|x| add_species_list(x)}
  end

  def remove_species_lists(imgs)
    imgs.each {|x| remove_species_list(x)}
  end

  # Add image this project if not already done so.  Saves it.
  def add_image(img)
    unless images.include?(img)
      images.push(img)
      Transaction.put_project(
        :id => self,
        :add_image => img
      )
    end
  end

  # Remove image this project. Saves it.
  def remove_image(img)
    if images.include?(img)
      images.delete(img)
      update_attribute(:updated_at, Time.now)
      Transaction.put_project(
        :id => self,
        :del_image => img
      )
    end
  end

  # Add observation (and its images) to this project if not already done so.  Saves it.
  def add_observation(obs)
    unless observations.include?(obs)
      imgs = obs.images.select {|img| img.user_id == obs.user_id}
      observations.push(obs)
      for img in imgs
        images.push(img)
      end
      Transaction.put_project(
        :id => self,
        :add_observation => obs,
        :add_images => imgs
      )
    end
  end

  # Remove observation (and its images) from this project. Saves it.
  def remove_observation(obs)
    if observations.include?(obs)
      imgs = obs.images.select {|img| img.user_id == obs.user_id}
      if imgs.any?
        img_ids = imgs.map(&:id).map(&:to_s).join(',')
        # Leave images which are attached to other observations still attached to this project.
        leave_these_img_ids = Image.connection.select_values(%(
          SELECT io.image_id FROM images_observations io, observations_projects op
          WHERE io.image_id IN (#{img_ids})
            AND io.observation_id != #{obs.id}
            AND io.observation_id = op.observation_id
            AND op.project_id = #{id}
        )).map(&:to_i)
        imgs.reject! {|img| leave_these_img_ids.include?(img.id)}
      end
      observations.delete(obs)
      for img in imgs
        images.delete(img)
      end
      update_attribute(:updated_at, Time.now)
      Transaction.put_project(
        :id => self,
        :del_observation => obs,
        :del_images => imgs
      )
    end
  end

  # Add species_list to this project if not already done so.  Saves it.
  def add_species_list(spl)
    unless species_lists.include?(spl)
      species_lists.push(spl)
      Transaction.put_project(
        :id => self,
        :add_species_list => spl
      )
    end
  end

  # Remove species_list from this project. Saves it.
  def remove_species_list(spl)
    if species_lists.include?(spl)
      species_lists.delete(spl)
      update_attribute(:updated_at, Time.now)
      Transaction.put_project(
        :id => self,
        :del_species_list => spl
      )
    end
  end

  ##############################################################################
  #
  #  :section: Logging
  #
  ##############################################################################

  def log_create; do_log(:log_project_created_at, true); end
  def log_update; do_log(:log_project_updated_at, true); end
  def log_destroy; do_log(:log_project_destroyed, true); end
  def log_add_member(user); do_log(:log_project_added_member, true, user); end
  def log_remove_member(user); do_log(:log_project_removed_member, false, user); end
  def log_add_admin(user); do_log(:log_project_added_admin, false, user); end
  def log_remove_admin(user); do_log(:log_project_removed_admin, false, user); end

  def do_log(tag, touch, user=nil)
    args = {}
    args[:name]  = user.login if user
    args[:touch] = touch
    if tag == :log_project_destroyed
      orphan_log(tag, args)
    else
      log(tag, args)
    end
  end

  ##############################################################################
  #
  #  :section: Callbacks
  #
  ##############################################################################

  # When deleting a project, "orphan" its unpublished drafts and remove the
  # user groups.
  def orphan_drafts
    title       = self.title
    user_group  = self.user_group
    admin_group = self.admin_group
    for d in NameDescription.find_all_by_source_type_and_project_id(:project, self.id)
      d.source_type = :source
      d.admin_groups.delete(admin_group)
      d.writer_groups.delete(admin_group)
      d.reader_groups.delete(user_group)
      d.save
    end
    user_group.destroy if user_group
    admin_group.destroy if admin_group
  end

################################################################################

protected

  def validation # :nodoc:
    if !self.user && !User.current
      errors.add(:user, :validate_project_user_missing.t)
    end
    if !self.admin_group
      errors.add(:admin_group, :validate_project_admin_group_missing.t)
    end
    if !self.user_group
      errors.add(:user_group, :validate_project_user_group_missing.t)
    end

    if self.title.to_s.blank?
      errors.add(:title, :validate_project_title_missing.t)
    elsif self.title.binary_length > 100
      errors.add(:title, :validate_project_title_too_long.t)
    end
  end
end
