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

    it "should clear out tags when set to nil" do
      m = MyModel.create!(tags: "hey,there")
      m.tags = nil
      m.tags_array.should == []
    end

    it "should clear out tags when set to empty string" do
      m = MyModel.create!(tags: "hey,there")
      m.tags = ""
      m.tags_array.should == []
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
      m = MyModel.create!(:tags => "food,ant,bee")
      m.tags = 'juice,food'
      MyModel.should_receive(:save_tags_index!) {double("scope").as_null_object}
      m.save
    end

    it 'should not launch the map/reduce if index activate and tag_arrays not change' do
      m = MyModel.create!(:tags => "food,ant,bee")
      MyModel.should_not_receive(:save_tags_index!)
      m.save
      m.name = 'hello'
      m.save
    end




  end

  context 'finding similarities based on tags' do

    before :each do
      @john = MyModel.create!({tags: 'a, b, c, d, e', name:'John'})
      @paul = MyModel.create!({tags: 'a, b, x, y, z', name: 'Paul'})
      @george = MyModel.create!({tags: 'v, w, x, y, z', name: 'George'})
      @ringo = MyModel.create!({tags: 'm, n, o, p, q', name: 'Ringo'})
    end


    it 'should find a similar item based on tags' do
      related = @john.find_related
      expect(related).to be_kind_of(Array)
      related.should have(1).items
      related.should include(@paul)
    end

     it 'related items should be in order of similarity' do
      related = @paul.find_related
      expect(related).to be_kind_of(Array)
      related.should have(2).items
      related[0].should == @george
      related[1].should == @john
    end

  end


  context 'similarity finding speed' do
    before :each do
      MyModel.disable_tags_index!
      start_time = Time.now
      @number_of_items = 1000
      create_many_tagged_items(@number_of_items)
      @time_to_create = Time.now-start_time
      MyModel.enable_tags_index!
    end

    it 'should be roughly linear to create (within 20%)' do
      MyModel.disable_tags_index!
      test_start_time = Time.now
      factor = 10
      test_items = @number_of_items/factor
      create_many_tagged_items(test_items)
      test_time = Time.now-test_start_time
      MyModel.enable_tags_index!
      allowance = 0.2
      expect(test_time).to be < @time_to_create/(factor*(1-allowance))
    end


    it 'made tagged objects, ordered by decreasing similarity' do
      MyModel.count.should eq(@number_of_items)

      testObj = MyModel.create!({tags: "a,b,c", name: 'test'})
      related = testObj.find_related
      # Related should have objects tagged with at least one thing in testObj
      expect(related).to be_kind_of(Array)
      max_similar_tags = 3

      related.each do |r|
        expect(r.tags).to match(/(a)|(b)|(c)/)
        similar_tags = r.tags_array.count {|x| ["a", "b", "c"].include? x }
        expect(similar_tags).to be <= max_similar_tags
        max_similar_tags = similar_tags
      end

    end


  end


  context 'creating large number of items' do
    before :each do
      MyModel.disable_tags_index!
      start_time = Time.now
      @number_of_items = 10000
      create_many_tagged_items(@number_of_items)
      @time_to_create = Time.now-start_time
      MyModel.enable_tags_index!
    end

    it 'should take roughly the same time with indexing or not (within 10%)' do
      MyModel.disable_tags_index!
      MyModel.tags.should be_empty
      MyModel.enable_tags_index!
      MyModel.should_receive(:save_tags_index!).exactly(@number_of_items).times
      MyModel.should_receive(:index_tags_now!).and_call_original
      test_start_time = Time.now
      create_many_tagged_items(@number_of_items)
      test_time = Time.now-test_start_time
      expect(test_time - @time_to_create).to be < @time_to_create/10
      tags = MyModel.tags #this should cause indexing
      tags.should_not be_empty
    end
  end


  LETTERS = ('a'..'z').to_a

  def create_many_tagged_items(number_to_create)
    number_to_create.times do |x|
      create_tagged_item(x.to_s)
    end
  end

  def create_tagged_item(name = "", tags_at_least = 2, tags_at_most = 7)
    tags = LETTERS.sample(rand(tags_at_least..tags_at_most))
    MyModel.create!({tags: tags.join(','), name: name})
  end

end
