require File.join(File.dirname(__FILE__), 'test_helper')

class EncodingTest < Test::Unit::TestCase

  # =?utf-8?Q? Nicolas=20Fouch=E9?= is not UTF-8, it's ISO-8859-1 !
  def test_marked_as_utf_8_but_it_is_iso_8859_1
    mail = load_fixture('marked_as_utf_8_but_it_is_iso_8859_1.txt')
    
    name = mail.to_addrs.first.name
    assert_equal ' Nicolas Fouché', TMail::Unquoter.unquote_and_convert_to(name, 'utf-8')

    # Without the patch, TMail raises:
    #  Iconv::InvalidCharacter: "\351"
    #  method iconv in quoting.rb at line 99
    #  method convert_to in quoting.rb at line 99
    #  method unquote_quoted_printable_and_convert_to in quoting.rb at line 88
    #  method unquote_and_convert_to in quoting.rb at line 72
    #  method gsub in quoting.rb at line 63
    #  method unquote_and_convert_to in quoting.rb at line 63
  end
  
  # =?iso-8859-1?b?77y5772B772O772Q772J772O772HIA==?= =?iso-8859-1?b?77y377yh77yu77yn?= is not ISO-8859-1, it's UTF-8 !
  def test_marked_as_iso_8859_1_but_it_is_utf_8
    mail = load_fixture('marked_as_iso_8859_1_but_it_is_utf_8.txt')
    
    name = mail.to_addrs.first.name
    assert_equal 'Ｙａｎｐｉｎｇ  ＷＡＮＧ', TMail::Unquoter.unquote_and_convert_to(name, 'utf-8')
    # Even GMail could not detect this one :)
    
    # Without the patch, TMail returns: "ï¼¹ï½ï½ï½ï½ï½ï½  ï¼·ï¼¡ï¼®ï¼§"
  end
  
  # Be sure not to copy/paste the content of the fixture to another file, it could be automatically converted to utf-8
  def test_iso_8859_1_email_without_encoding_and_message_id
    mail = load_fixture('iso_8859_1_email_without_encoding_and_message_id.txt')
    
    text = TMail::Unquoter.unquote_and_convert_to(mail.body, 'utf-8')

    assert(text.include?('é'), 'Text content should include the "é" character')
    
    # I'm not very proud of this one, chardet detects iso-8859-2, so I have to force the encoding to iso-8859-1.
    assert(!text.include?('ŕ'), 'Text content should not iso-8859-2, "ŕ" should be "à"')
    
    # Without the patch, TMail::Unquoter.unquote_and_convert_to returns:
    #  Il semblerait que vous n'ayez pas consult� votre messagerie depuis plus
    #  d'un an. Aussi, celle-ci a �t� temporairement desactiv�e.
    #  Aucune demande n'est necessaire pour r�activer votre messagerie : la simple
    #  consultation de ce message indique que la boite est � nouveau utilisable.
  end
end