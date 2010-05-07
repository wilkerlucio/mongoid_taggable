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

module Mongoid::Taggable
  def self.included(base)
    # create fields for tags and index it
    base.field :tags_array, :type => Array
    base.index [['tags_array', Mongo::ASCENDING]]
    
    # add callback to save tags index
    base.after_save do |document|
      document.class.save_tags_index!
    end
    
    # extend model
    base.extend         ClassMethods
    base.send :include, InstanceMethods
    
    # enable indexing as default
    base.enable_tags_index!
  end
  
  module ClassMethods
    # get an array with all defined tags for this model, this list returns
    # an array of distinct ordered list of tags defined in all documents
    # of this model
    def tags
      db = Mongoid::Config.instance.master
      db.collection(tags_index_collection).find.to_a.map{ |r| r["_id"] }
    end
    
    # retrieve the list of tags with weight(count), this is usefull for
    # creating tag clouds
    def tags_with_weight
      db = Mongoid::Config.instance.master
      db.collection(tags_index_collection).find.to_a.map{ |r| [r["_id"], r["value"]] }
    end
    
    def disable_tags_index!
      @do_tags_index = false
    end
    
    def enable_tags_index!
      @do_tags_index = true
    end
    
    def tags_separator(separator = nil)
      @tags_separator = separator if separator
      @tags_separator || ','
    end
    
    def tags_index_collection
      "#{collection_name}_tags_index"
    end

    def save_tags_index!
      return unless @do_tags_index
      
      db = Mongoid::Config.instance.master
      coll = db.collection(collection_name)

      map = "function() {
        if (!this.tags_array) {
          return;
        }

        for (index in this.tags_array) {
          emit(this.tags_array[index], 1);
        }
      }"

      reduce = "function(previous, current) {
        var count = 0;

        for (index in current) {
          count += current[index]
        }

        return count;
      }"

      coll.map_reduce(map, reduce, :out => tags_index_collection)
    end
  end
  
  module InstanceMethods
    def tags
      (tags_array || []).join(self.class.tags_separator)
    end
    
    def tags=(tags)
      self.tags_array = tags.split(self.class.tags_separator).map(&:strip)
    end
  end
end
