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
  extend ActiveSupport::Concern

  included do
    # create fields for tags and index it
    field :tags_array, :type => Array, :default => []
    index({ tags_array: 1 })

    # add callback to save tags index
    after_save do |document|
      document.class.save_tags_index! if document.tags_array_changed?
    end

    # enable indexing as default
    enable_tags_index!
  end

  module ClassMethods
    # returns an array of distinct ordered list of tags defined in all documents

    def tagged_with(tag)
      self.any_in(:tags_array => [tag])
    end

    def tagged_with_all(*tags)
      self.all_in(:tags_array => tags.flatten)
    end

    def tagged_with_any(*tags)
      self.any_in(:tags_array => tags.flatten)
    end

    def tags
      tags_index_collection.find.to_a.map{ |r| r["_id"] }
    end

    # retrieve the list of tags with weight (i.e. count), this is useful for
    # creating tag clouds
    def tags_with_weight
      tags_index_collection.find.to_a.map{ |r| [r["_id"], r["value"]] }
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

    def tags_index_collection_name
      "#{collection_name}_tags_index"
    end

    def tags_index_collection
      @tags_index_collection ||= Moped::Collection.new(self.collection.database, tags_index_collection_name)
    end

    def save_tags_index!
      return unless @do_tags_index

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

      # Since map_reduce is normally lazy-executed, call 'raw'
      # Should not be influenced by scoping. Let consumers worry about
      # removing tags they wish not to appear in index.
      self.unscoped.map_reduce(map, reduce).out(replace: tags_index_collection_name).raw
    end
  end


  def tags
    (tags_array || []).join(self.class.tags_separator)
  end

  def tags=(tags)
    if tags.present?
      self.tags_array = tags.split(self.class.tags_separator).map(&:strip).reject(&:blank?)
    else
     self.tags_array = []
    end
  end

  def save_tags_index!
    self.class.save_tags_index!
  end
end