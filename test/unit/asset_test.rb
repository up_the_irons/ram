require File.dirname(__FILE__) + '/../test_helper'

class AssetTest < Test::Unit::TestCase
  fixtures :collections, :attachments, :db_files, :linkings, :users, :memberships

  def setup
  		@model = Asset
  		@record_one = Asset.find(1)
  		@new_obj = {
  			:filename => 'rails.png',
  			:size=> 4,
  			:content_type => 'image/png',
  			:linking =>Linking.find(1)
  		}
  end

  #test based on the acts_as_attachment test examples
  def test_should_create_image_from_uploaded_file
    assert_created Asset do
      attachment = upload_file :filename => '../fixtures/images/rails.png'
      assert !attachment.new_record?, attachment.errors.full_messages.join("\n")
      assert !attachment.db_file.new_record? if attachment.respond_to?(:db_file)
      assert  attachment.image?
      assert !attachment.size.zero?
      assert_equal 50,   attachment.width
      assert_equal 64,   attachment.height
    end
  end
  
  def test_assets_should_have_groups
    Asset.find(:all).each do |a |
      assert a.groups.size >= 0
    end
  end
  
  def test_assets_should_have_categories
    Asset.find(:all).each do |a|
      assert a.category
    end
  end
  
  def test_assets_shall_not_belong_to_the_same_group_twice
    #todo: this silently fails would be good to bubble up some errors
    a = Asset.find(:first)
    assert_no_difference a.groups, :count do
      a.groups << a.groups.find(:first)
    end
  end
  
  def test_destroying_an_asset_shall_destroy_their_linkings
    
    #test fixtures contain 11 linkings so once deleted the linking count should be reduced by 11
    assert_difference Linking, :count, -11 do
      Asset.find(:all). each do |a|
        a.destroy()
      end
    end
  end

  def test_search
    [{:groups => [collections(:collection_4).id, collections(:collection_3).id], :expected_num_of_results => 2},
     {:groups => [collections(:collection_4).id], :expected_num_of_results => 1}].each do |h|
      groups = h[:groups]
      results = Asset.search('nes', groups)

      # With current fixture data, we expect 2 results
      assert_equal h[:expected_num_of_results], results.size

      results.each do |r|
        # Assert we got assets only in the groups we queried
        assert !(r.groups.map { |o| o.id } & groups).empty? 
      end
    end
  end
  
  #Taken from the attachment_test.rb file that ships with acts_as_attachment
  protected
    def upload_file(options = {})
      att = (options[:class] || Attachment).create :uploaded_data => fixture_file_upload(options[:filename], options[:content_type] || 'image/png')
      att.reload unless att.new_record?
      att
    end
    
    def assert_created(klass = Attachment, num = 1)
      assert_difference klass, :count, num do
        if klass.included_modules.include? DbFile
          assert_difference DbFile, :count, num do
            yield
          end
        else
          yield
        end
      end
    end
    
    def assert_not_created
      assert_created Attachment, 0 do
        yield
      end
    end
    
    def should_reject_by_size_with(klass)
      assert_not_created do
        attachment = upload_file :class => klass, :filename => '/files/rails.png'
        assert attachment.new_record?
        assert attachment.errors.on(:size)
        assert_nil attachment.db_file if attachment.respond_to?(:db_file)
      end
    end
end
