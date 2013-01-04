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
  field :name
end

describe Mongoid::Taggable do

  describe "default tags array value" do
    it 'should be an empty array' do
      MyModel.new.tags_array.should == []
    end
  end

  context "finding" do
    let(:model){MyModel.create!(:tags => "interesting,stuff,good,bad")}
    context "by tagged_with" do
      let(:models){MyModel.tagged_with('interesting')}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_all using an array" do
      let(:models){MyModel.tagged_with_all(['interesting', 'good'])}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_all using strings" do
      let(:models){MyModel.tagged_with_all('interesting', 'good')}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_all when tag not included" do
      let(:models){MyModel.tagged_with_all('interesting', 'good', 'mcdonalds')}
      it "locates tagged objects" do
        models.include?(model).should be_false
      end
    end
    context "by tagged_with_any using an array" do
      let(:models){MyModel.tagged_with_any(['interesting', 'mcdonalds'])}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_any using strings" do
      let(:models){MyModel.tagged_with_any('interesting', 'mcdonalds')}
      it "locates tagged objects" do
        models.include?(model).should be_true
      end
    end
    context "by tagged_with_any when tag not included" do
      let(:models){MyModel.tagged_with_any('hardees', 'wendys', 'mcdonalds')}
      it "locates tagged objects" do
        models.include?(model).should be_false
      end
    end
  end

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

    it "should not put empty tags in array" do
      @m.tags = "repetitive,, commas, shouldn't cause,,, empty tags"
      @m.tags_array.should == ["repetitive", "commas", "shouldn't cause", "empty tags"]
    end
  end

  context "changing separator" do
    before :all do
      MyModel.tags_separator ";"
    end

    after :all do
      MyModel.tags_separator ","
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
      MyModel.tags_index_collection_name.should == "my_models_tags_index"
    end

    it "should generate the index collection model based on model" do
      MyModel.tags_index_collection.should be_a Moped::Collection
    end

    it "should generate the index collection model based on model with the collection name" do
      MyModel.tags_index_collection.name.should == "my_models_tags_index"
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
        MyModel.disable_tags_index!
      end

      after :all do
        MyModel.enable_tags_index!
      end

      it "should not generate index" do
        MyModel.create!(:tags => "sample,tags")
        MyModel.tags.should == []
      end
    end

    it 'should launch the map/reduce if index activate and tag_arrays change' do
      m = MyModel.create!(:tags_ => %w("food ant bee"))
      m.tags = 'juice,food'
      m.should_receive(:save_tags_index!)
      m.save
    end

    it 'should not launch the map/reduce if index activate and tag_arrays not change' do
      m = MyModel.create!(:tags => "food,ant,bee")
      m.should_not_receive(:save_tags_index!)
      m.save
      m.name = 'hello'
      m.save
    end

  end

end
