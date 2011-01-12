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
    cattr_accessor :tags_field, :tags_separator, :tag_aggregation

    set_callback :save, :after, :if => proc { should_update_tag_aggregation? } do |document|
      document.class.aggregate_tags!
    end
  end

  module ClassMethods
    def taggable(*args)
      options = args.extract_options!
      options.reverse_merge!(
        :separator => ',',
        :aggregation => false
      )

      self.tags_field      = args.blank? ? :tags_array : args.shift
      self.tags_separator  = options[:separator]
      self.tag_aggregation = options[:aggregation]

      field tags_field, :type => Array
      index tags_field
    end

    # get an array with all defined tags for this model, this list returns
    # an array of distinct ordered list of tags defined in all documents
    # of this model
    def tags
      db = Mongoid::Config.instance.master
      db.collection(tags_aggregation_collection).find.to_a.map{ |r| r["_id"] }
    end

    # retrieve the list of tags with weight(count), this is useful for
    # creating tag clouds
    def tags_with_weight
      db = Mongoid::Config.instance.master
      db.collection(tags_aggregation_collection).find.to_a.map{ |r| [r["_id"], r["value"]] }
    end

    def aggregate_tags?
      !!tag_aggregation
    end

    def tags_aggregation_collection
      "#{collection_name}_tags_aggregation"
    end

    def aggregate_tags!
      return unless aggregate_tags?

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

      coll.map_reduce(map, reduce, :out => tags_aggregation_collection)
    end

    def tagged_with(_tags)
      _tags = convert_string_tags_to_array(_tags) if _tags.is_a? String
      criteria.all_in(tags_field => _tags)
    end

    def convert_string_tags_to_array(_tags)
      (_tags).split(tags_separator).map(&:strip)
    end
  end

  module InstanceMethods
    def tags
      (tags_array || []).join(self.class.tags_separator)
    end

    def tags=(tags)
      self.tags_array = self.class.convert_string_tags_to_array(tags)
    end

  private
    def should_update_tag_aggregation?
      self.class.aggregate_tags? &&                   # vvv new record
        previous_changes.include?(tags_field.to_s) || previous_changes.blank?
    end
  end

end

