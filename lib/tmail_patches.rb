require 'rubygems'

gem 'tmail', '= 1.2.3.1'
require 'tmail'

require 'kconv'
require 'rchardet'
require 'activesupport'

# To act like any webmail, we have to continue parsing a mail part even if there's a problem in the header.
# Those malformed lines and the following ones are then ignored.
TMail::Mail.class_eval do
private
  def parse_header_with_fail_safe(f)
    begin
      parse_header_without_fail_safe(f)
    rescue
      warn($!.class.to_s + ': ' + $!.message + ' - ' + $!.backtrace.join(', '))
    end
  end
  alias_method_chain :parse_header, :fail_safe
end

# TMail does not detect that an email can be an attachment by itself, i.e. contains one single part which is an attachment.
# A bug has been submitted to the project's bugtracker: http://rubyforge.org/tracker/index.php?func=detail&aid=23099&group_id=4512&atid=17370
# Also added the detection of inline attachments
TMail::Mail.class_eval do
  def has_attachments?
    attachment?(self) || multipart? && parts.any? { |part| attachment?(part) }
  end
  
  # Returns true if this part's content main type is text, else returns false.
  # By main type is meant "text/plain" is text.  "text/html" is text
  def text_content_type?
    self.header['content-type'] && (self.header['content-type'].main_type == 'text')
  end
  
  def inline_attachment?(part)
    part['content-id'] || (part['content-disposition'] && part['content-disposition'].disposition == 'inline' && !part.text_content_type?)
  end
  
  def attachment?(part)
    part.disposition_is_attachment? || (!part.content_type.nil? && !part.text_content_type?) unless part.multipart?
  end
  
  def attachments
    if multipart?
      parts.collect { |part| attachment(part) }.flatten.compact
    elsif attachment?(self)
      [attachment(self)]
    end
  end
  
private
  def attachment(part)
    if part.multipart?
      part.attachments
    elsif attachment?(part)
      content   = part.body # unquoted automatically by TMail#body
      file_name = (part['content-location'] && part['content-location'].body) ||
                  part.sub_header('content-type', 'name') ||
                  part.sub_header('content-disposition', 'filename') ||
                  'noname'
      
      return if content.blank?
      
      attachment = TMail::Attachment.new(content)
      attachment.original_filename = file_name.strip unless file_name.blank?
      attachment.content_type = part.content_type
      attachment
    end
  end
end

# Try to detect charset of texts before converting them to utf-8.
# -Quoted printable- can specify wrong encoding.
# In that case, we fall back on supposing that the original encoding is iso_8859_1.
# Example: =?utf-8?Q? Nicolas=20Fouch=E9?= <xx.xx@xx.com>
# It is marked as utf-8 but it's iso_8859_1.
TMail::Unquoter.class_eval do
  class << self
    def convert_to_with_fallback_on_iso_8859_1(text, to, from)
      return text if to == 'utf-8' and text.isutf8
      
      if from.blank? and !text.is_binary_data?
        from = CharDet.detect(text)['encoding']
        
        # Chardet ususally detects iso-8859-2 (aka windows-1250), but the text is
        # iso-8859-1 (aka windows-1252 and Latin1). http://en.wikipedia.org/wiki/ISO/IEC_8859-2
        # This can cause unwanted characters, like ŕ instead of à.
        # (I know, could be a very bad decision...)
        from = 'iso-8859-1' if from =~ /iso-8859-2/i
      end
      
      begin
        convert_to_without_fallback_on_iso_8859_1(text, to, from)
      rescue Iconv::InvalidCharacter
        unless from == 'iso-8859-1'
          from = 'iso-8859-1'
          retry
        end
      end
    end
    alias_method_chain :convert_to, :fallback_on_iso_8859_1
  end
end
