require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), '../lib/tmail_patches')

class TMailPatchesTest < Test::Unit::TestCase

  def setup
  end
  
  # TMail::Mail.has_attachments? & TMail::Mail.attachments
  # http://rubyforge.org/tracker/index.php?func=detail&aid=23099&group_id=4512&atid=17370
  def test_the_only_part_is_a_word_document
    mail = load_fixture('the_only_part_is_a_word_document.txt')
    
    assert_equal('application/msword', mail.content_type)
    assert !mail.multipart?, 'The mail should not be multipart'
    assert mail.attachment?(mail), 'The mail should be considered has an attachment'
    
    # The original method TMail::Mail.has_attachments? returns false
    assert mail.has_attachments?, 'PATCH: TMail should consider that this email has an attachment'
    
    # The original method TMail::Mail.attachments returns nil
    assert_not_nil mail.attachments, 'PATCH: TMail should return the attachment'
    assert_equal 1, mail.attachments.size, 'PATCH: TMail should detect one attachment'
    assert_instance_of TMail::Attachment, mail.attachments.first, 'The first attachment found should be an instance of TMail::Attachment'
  end

  # new method TMail::Mail.inline_attachment?
  def test_inline_attachment_should_detect_inline_attachments
    mail = load_fixture('inline_attachment.txt')
    
    assert !mail.inline_attachment?(mail.parts[0]), 'The first part is an empty text'
    assert mail.inline_attachment?(mail.parts[1]), 'The second part is an inline attachment'
    
    mail = load_fixture('the_only_part_is_a_word_document.txt')
    assert !mail.inline_attachment?(mail), 'The first and only part is an normal attachment'
  end
  
  # new method TMail::Mail.text_content_type?
  def test_text_content_type?
    mail = load_fixture('inline_attachment.txt')
    
    assert mail.parts[0].text_content_type?, 'The first part of inline_attachment.txt is a text'
    assert !mail.parts[1].text_content_type?, 'The second part of inline_attachment.txt is not a text'
  end

protected

  def load_fixture(name)
    TMail::Mail.load(File.join(FIXTURES_PATH, name))
  end

end