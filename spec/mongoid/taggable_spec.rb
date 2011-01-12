# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class MyModel
  include Mongoid::Document
  include Mongoid::Taggable

  field :attr
  taggable
end

describe Mongoid::Taggable do
  context "saving tags from plain text" do
    before :each do
      @m = MyModel.new
    end

    it "should set tags array from string" do
      @m.tags = "some,new,tag"
      @m.tags_array.should == %w[some new tag]
    end

    it "should retrieve tags string from array" do
      @m.tags_array = %w[some new tags]
      @m.tags.should == "some,new,tags"
    end

    it "should strip tags before put in array" do
      @m.tags = "now ,  with, some spaces  , in places "
      @m.tags_array.should == ["now", "with", "some spaces", "in places"]
    end
  end

  context "changing separator" do
    before :all do
      MyModel.tags_separator = ";"
    end

    after :all do
      MyModel.tags_separator = ","
    end

    before :each do
      @m = MyModel.new
    end

    it "should split with custom separator" do
      @m.tags = "some;other;separator"
      @m.tags_array.should == %w[some other separator]
    end

    it "should join with custom separator" do
      @m.tags_array = %w[some other sep]
      @m.tags.should == "some;other;sep"
    end
  end

  context "indexing tags" do
    it "should generate the index collection name based on model" do
      MyModel.tags_index_collection.should == "my_models_tags_index"
    end

    context "retrieving index" do
      before :each do
        MyModel.create!(:tags => "food,ant,bee")
        MyModel.create!(:tags => "juice,food,bee,zip")
        MyModel.create!(:tags => "honey,strip,food")
      end

      it "should retrieve the list of all saved tags distinct and ordered" do
        MyModel.tags.should == %w[ant bee food honey juice strip zip]
      end

      it "should retrieve a list of tags with weight" do
        MyModel.tags_with_weight.should == [
          ['ant', 1],
          ['bee', 2],
          ['food', 3],
          ['honey', 1],
          ['juice', 1],
          ['strip', 1],
          ['zip', 1]
        ]
      end
    end

    context "avoiding index generation" do
      before :all do
        MyModel.index_tag_weights = false
      end

      after :all do
        MyModel.index_tag_weights = true
      end

      it "should not generate index" do
        MyModel.create!(:tags => "sample,tags")
        MyModel.tags.should == []
      end
    end
  end

  context "#self.tagged_with" do
    before(:each) do
      @m1 = MyModel.create! :tags => "tag1,tag2,tag3"
      @m2 = MyModel.create! :tags => "tag2"
      @m3 = MyModel.create! :tags => "tag1", :attr => "value"
    end

    it "should return all tags with single tag input" do
      MyModel.tagged_with("tag2").sort_by{|a| a.id.to_s}.should == [@m1, @m2].sort_by{|a| a.id.to_s}
    end

    it "should return all tags with tags array input" do
      MyModel.tagged_with(%w{tag2 tag1}).should == [@m1]
    end

    it "should return all tags with tags string input" do
      MyModel.tagged_with("tag2,tag1").should == [@m1]
    end

    it "should be able to be part of methods chain" do
      MyModel.tagged_with("tag1").where(:attr => "value").should == [@m3]
    end
  end
end
