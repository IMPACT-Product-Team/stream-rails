require 'active_record'
require 'spec_helper'
require 'spec_database'

describe 'activity class implementations' do
  before do
    @tom = User.new
    @tom.save!

    @denver = Location.new
    @denver.name = 'Denver, CO'
    @denver.save!
  end

  def use_model(activity_model)
    @activity_model = activity_model
    ActiveRecord::Migration.create_table activity_model.table_name do |t|
      t.integer :user_id
      t.timestamps
    end
  end

  def has_activity_methods
    instance = @activity_model.new
    instance.should respond_to(:activity_actor_id)
    instance.should respond_to(:activity_verb)
    instance.should respond_to(:activity_target)
    instance.should respond_to(:activity_object_id)
    instance.should respond_to(:activity_target_id)
    instance.should respond_to(:activity_notify)
    instance.should respond_to(:activity_extra_data)
    instance.should respond_to(:activity_should_sync?)
    instance.should respond_to(:create_activity)
  end

  def try_delete
    instance = @activity_model.new
    instance.user = @tom
    instance.save!
    instance.destroy
  end

  def build_activity_with_location
    instance = @activity_model.new
    instance.user = @tom
    instance.extra_data = { location: "location:#{@denver.id}" }
    instance.save!
    instance.create_activity
  end

  def build_activity
    instance = @activity_model.new
    instance.user = @tom
    instance.save!
    instance.create_activity
  end

  context 'Article' do
    before(:all) { use_model(Article) }
    specify { has_activity_methods }
    specify { try_delete }
    specify do
      activity = build_activity_with_location
      activity[:to].should eq nil
      activity[:actor].should_not eq nil
      activity[:verb].should_not eq nil
      activity[:object].should_not eq nil
    end
  end

  context 'Tweet' do
    before(:all) { use_model(Tweet) }
    specify { has_activity_methods }
    specify { try_delete }
    specify do
      activity = build_activity
      activity[:actor].should_not eq nil
      activity[:verb].should_not eq nil
      activity[:object].should_not eq nil
      activity[:target].should_not eq nil
      activity[:parent_tweet].should eq 1
      activity[:parent_author].should eq 2
      activity[:to].should eq ['notification:cesar']
    end
  end

  context 'Pin' do
    before(:all) { use_model(Pin) }
    specify { has_activity_methods }
    specify { @activity_model.new.should respond_to(:custom_save) }
    specify { try_delete }
    specify do
      activity = build_activity
      activity[:to].should eq nil
      activity[:actor].should eq 'cesar'
      activity[:verb].should_not eq nil
      activity[:object].should_not eq nil
    end
  end

  context 'PoorlyImplementedActivity' do
    before(:all) { use_model(PoorlyImplementedActivity) }
    specify { has_activity_methods }
    specify do
      activity = PoorlyImplementedActivity.new

      error_message = 'Activity models must define `#activity_object` - missing on `PoorlyImplementedActivity`'
      expect { activity.activity_object }.to raise_error(NotImplementedError, error_message)
    end
  end
end
