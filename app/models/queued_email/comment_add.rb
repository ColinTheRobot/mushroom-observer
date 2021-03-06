# encoding: utf-8

# Comment Email
class QueuedEmail::CommentAdd < QueuedEmail
  def comment; get_object(:comment, Comment); end

  def self.find_or_create_email(sender, receiver, comment)
    # Check for an already queued matching email
    email = QueuedEmail.find(:first, :include => :queued_email_integers,
      :conditions => [
        'queued_emails.to_user_id = ?
          AND queued_emails.flavor = "QueuedEmail::CommentAdd"
          AND queued_email_integers.key = "comment"
          AND queued_email_integers.value = ?', receiver.id, comment.id])
    if email
      # Only happens when queuing is enabled, just touch 'queued' time.
      email.queued = Time.now
      email.save
    else
      email = create(sender, receiver)
      raise "Missing comment!" if !comment
      email.add_integer(:comment, comment.id)
      email.finish
    end
    return email
  end

  def deliver_email
    # Make sure it hasn't been deleted since email was queued.
    if comment
      CommentEmail.build(user, to_user, comment.target, comment).deliver
    end
  end
end
