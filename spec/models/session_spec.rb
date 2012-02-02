# AirCasting - Share your Air!
# Copyright (C) 2011-2012 HabitatMap, Inc.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# You can contact the authors by email at <info@habitatmap.org>

require 'spec_helper'

describe Session do
  describe 'validations' do
    before { Factory(:session) }

    it { should validate_presence_of :uuid }
    it { should validate_uniqueness_of :uuid }
    it { should validate_uniqueness_of :url_token }
    it { should validate_presence_of :calibration }
    it { should validate_presence_of :offset_60_db }
    it { should ensure_inclusion_of(:offset_60_db).in_range(-5..5) }
  end

  describe 'mass assignment' do
    it { should allow_mass_assignment_of :data_type }
    it { should allow_mass_assignment_of :instrument }
    it { should allow_mass_assignment_of :phone_model }
    it { should allow_mass_assignment_of :os_version }
  end

  describe "#as_json" do
    let(:m1) { Factory(:measurement) }
    let(:m2) { Factory(:measurement) }
    let(:session) { Factory(:session, :measurements => [m1, m2]) }

    subject { session.as_json }

    it "should include session size" do
      subject.symbolize_keys[:size].should == session.reload.measurements.size
    end
  end

  describe '.create' do
    let(:session) { Factory.build(:session) }

    it 'should call set_url_token' do
      session.should_receive(:set_url_token)
      session.save
    end
  end

  describe "#destroy" do
    let(:session) { Factory(:session) }
    let!(:measurement) { Factory(:measurement, :session => session) }

    it "should destroy measurements" do
      session.reload.destroy

      Measurement.exists?(measurement.id).should be_false
    end
  end

  describe '.filter' do
    before { Session.destroy_all }

    it 'should exclude not contributed sessions' do
      session1 = Factory(:session, :contribute => true)
      session2 = Factory(:session, :contribute => false)

      Session.filter.all.should == [session1]
    end

    it "should exclude sessions outside the area if given" do
      session1 = Factory(:session, :measurements => [Factory(:measurement, :longitude => 10, :latitude => 20)])
      session2 = Factory(:session, :measurements => [Factory(:measurement, :longitude => 20, :latitude => 20)])
      session3 = Factory(:session, :measurements => [Factory(:measurement, :longitude => 10, :latitude => 30)])

      Session.filter(:west => 5, :east => 15, :south => 15, :north => 25).all.should == [session1]
    end
  end

  describe '.filtered_json' do
    let(:data) { mock('data') }
    let(:records) { mock('records') }
    let(:json) { mock('json') }

    it 'should return filter() as json' do
      Session.should_receive(:filter).with(data).and_return(records)
      records.should_receive(:as_json).with(hash_including(:methods => [:username, :size])).and_return(json)

      Session.filtered_json(data).should == json
    end
  end

  describe '#set_url_token' do
    let(:token) { mock }
    let(:gen) { mock(:generate_unique => token) }

    before do
      TokenGenerator.stub!(:new => gen)
      subject.send(:set_url_token)
    end

    it 'sets url_token to one generated by TokenGenerator' do
      subject.url_token.should == token
    end
  end

  describe '#to_param' do
    let(:session) { Session.new }

    subject { session.to_param }

    it { should == session.url_token }
  end

  describe "#sync" do
    let(:session) { Factory(:session) }
    let!(:note) { Factory(:note, :session => session) }
    let(:data) { { :tag_list => "some tag or other", :notes => [] } }

    before { session.reload.sync(data) }

    it "should normalize tags" do
      session.reload.tags.count.should == 4
    end

    it "should delete notes" do
      Note.exists?(note.id).should be_false
    end
  end
end
