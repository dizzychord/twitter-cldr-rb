# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'spec_helper'

include TwitterCldr::Localized

describe LocalizedString do
  describe '#%' do
    context 'when argument is not a Hash' do
      it 'performs regular formatting of values' do
        ('%d is an integer'.localize % 3.14).should == '3 is an integer'
      end

      it 'performs regular formatting of arrays' do
        ('"% 04d" is a %s'.localize % [12, 'number']).should == '" 012" is a number'
      end

      it 'ignores pluralization placeholders' do
        ('%s: %{horses_count:horses}'.localize % 'total').should == 'total: %{horses_count:horses}'
      end

      it 'raises ArgumentError when the string contains named placeholder' do
        lambda { '%{msg}: %{horses_count:horses}'.localize % 'total' }.should raise_error(ArgumentError)
      end
    end

    context 'when argument is a Hash' do
      let(:horses) { { :one => '1 horse', :other => '%{horses_count} horses' } }

      before(:each) do
        stub(Formatters::Plurals::Rules).rule_for { |n, _| n == 1 ? :one : :other  }
      end

      it 'interpolates named placeholders' do
        ('%<num>.2f is a %{noun}'.localize % { :num => 3.1415, :noun => 'number' }).should == '3.14 is a number'
      end

      it 'performs regular pluralization' do
        ('%{horses_count:horses}'.localize % { :horses_count => 2, :horses => horses }).should == '2 horses'
      end

      it 'performs inline pluralization' do
        string = '%<{ "horses_count": { "other": "%{horses_count} horses" } }>'.localize
        (string % { :horses_count => 2 }).should == '2 horses'
      end

      it 'performs both formatting and regular pluralization simultaneously' do
        string = '%{msg}: %{horses_count:horses}'.localize
        (string % { :horses_count => 2, :horses => horses, :msg => 'result' }).should == 'result: 2 horses'
      end

      it 'performs both formatting and inline pluralization simultaneously' do
        string = '%{msg}: %<{"horses_count": {"other": "%{horses_count} horses"}}>'.localize
        (string % { :horses_count => 2, :msg => 'result' }).should == 'result: 2 horses'
      end

      it 'performs both formatted interpolation and inline pluralization simultaneously' do
        string = '%<number>d, %<{"horses_count": {"other": "%{horses_count} horses" }}>'.localize
        (string % { :number => 3.14, :horses_count => 2 }).should == '3, 2 horses'
      end

      it 'leaves regular pluralization placeholders unchanged if not enough information given' do
        string = '%{msg}: %{horses_count:horses}'.localize
        (string % { :msg => 'no pluralization' } ).should == 'no pluralization: %{horses_count:horses}'
      end

      it 'leaves inline pluralization placeholders unchanged if not enough information given' do
        string = '%<number>d, %<{"horses_count": {"one": "one horse"}}>'.localize
        (string % { :number => 3.14, :horses_count => 2 }).should == '3, %<{"horses_count": {"one": "one horse"}}>'
      end

      it 'raises KeyError when value for a named placeholder is missing' do
        lambda do
          '%{msg}: %{horses_count:horses}'.localize % { :horses_count => 2, :horses => horses }
        end.should raise_error(KeyError)
      end
    end
  end

  describe "#to_s" do
    it "should return a copy the base string" do
      string = "galoshes"
      result = string.localize.to_s

      result.should == string
      result.equal?(string).should_not be_true
    end
  end

  describe "#normalize" do
    let(:string) { 'string' }
    let(:normalized_string) { 'normalized' }
    let(:localized_string) { string.localize }

    it 'returns a LocalizedString' do
      localized_string.normalize.should be_an_instance_of(LocalizedString)
    end

    it 'it uses NFD by default' do
      mock(TwitterCldr::Normalization::NFD).normalize(string) { normalized_string }
      localized_string.normalize.base_obj.should == normalized_string
    end

    it "uses specified algorithm if there is any" do
      mock(TwitterCldr::Normalization::NFKD).normalize(string) { normalized_string }
      localized_string.normalize(:using => :NFKD).base_obj.should == normalized_string
    end

    it "raises an ArgumentError if passed an unsupported normalization form" do
      lambda { localized_string.normalize(:using => :blarg) }.should raise_error(ArgumentError)
    end
  end

  describe "#code_points" do
    it "returns an array of Unicode code points for the string" do
      "español".localize.code_points.should == [0x65, 0x73, 0x70, 0x61, 0xF1, 0x6F, 0x6C]
    end
  end

end