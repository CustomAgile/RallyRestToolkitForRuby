require "rspec"

require_relative "rally_api_spec_helper"
require_relative "../lib/rally_api/rally_object"

describe "Rally Json Object Tests" do

  JSON_TEST_OBJECT = { "Name" => "Test Name", "Severity" => "High", "_type" => "defect", "ScheduleState" => "In-Progress"}
  UPDATED_TEST_OBJECT = { "Name" => "Test Name", "Severity" => "High", "Priority" => "Very Important","_type" => "defect"}

  TASK1 = {"Name" => "Task 1", "_type" => "task"}
  TASK2 = {"Name" => "Task 2", "_type" => "task"}
  TASK3 = {"Name" => "Task 3", "_type" => "task"}
  TASK4 = {"Name" => "Task 4", "_type" => "task", "State" => "In-Progress"}
  CHILD_STORY1 = {"Name" => "Child 1", "Tasks" => [TASK1, TASK2], "_type" => "hierarchicalrequirement", "ScheduleState" => "Defined"}
  CHILD_STORY2 = {"Name" => "Child 2", "Tasks" => [TASK3, TASK4], "_type" => "hierarchicalrequirement", "ScheduleState" => "Defined"}
  NESTED_STORY = {"Name" => "Parent Story", "Children" => [CHILD_STORY1, CHILD_STORY2], "_type" => "hierarchicalrequirement", "ScheduleState" => "Defined"}

  before :each do
    @mock_rally = double("MockRallyRest")
    @mock_rally.stub(:reread => UPDATED_TEST_OBJECT)
    @mock_rally.stub(:rally_rest_api_compat => false)
  end

  it "should load a basic json hash" do
    test_object = RallyAPI::RallyObject.new(@mock_rally,JSON_TEST_OBJECT)
    test_object.nil?.should == false
    test_object.Name.should == "Test Name"
  end

  it "should call reread for a nil value" do
    test_object = RallyAPI::RallyObject.new(@mock_rally,JSON_TEST_OBJECT)
    test_object.read()
    test_object.Priority.should == "Very Important"
  end

  it "should be able to access a field with [] notation" do
    test_object = RallyAPI::RallyObject.new(@mock_rally,JSON_TEST_OBJECT)
    test_object["Severity"].should == "High"
  end

  it "should read a nested object attribute" do
    test_object = RallyAPI::RallyObject.new(@mock_rally, NESTED_STORY)

    test_object.Children[1].Tasks[1].Name.should == TASK4["Name"]
    test_object.Children[1].Name.should == CHILD_STORY2["Name"]
  end

  it "should return nil for field that has no value" do
    test_object = RallyAPI::RallyObject.new(@mock_rally,JSON_TEST_OBJECT)
    test_object.nil?.should == false
    test_object.Foo.nil?.should == true
  end

  it "should return a nil without lazy loading" do
    test_object = RallyAPI::RallyObject.new(@mock_rally, NESTED_STORY)
    @mock_rally.should_receive(:rally_rest_api_compat)
    test_object.nil?.should == false
    test_object.Foo.nil?.should == true
    test_object.Severity.nil?.should == true
    test_object.Children[1].Name.nil?.should == false
  end

  it "should allow setting a field by []" do
    test_object = RallyAPI::RallyObject.new(@mock_rally, NESTED_STORY)
    test_object.nil?.should == false
    new_desc = "A new description"
    test_object["Description"] = new_desc
    test_object.Description.should == new_desc
  end

  it "should respect the RallyRestAPI compatibility flag when reading a field" do
    mock_rally_with_compat = double("MockRallyRest")
    mock_rally_with_compat.stub(:rally_rest_api_compat => true)
    test_object = RallyAPI::RallyObject.new(mock_rally_with_compat, NESTED_STORY)
    test_object.schedule_state.should == NESTED_STORY["ScheduleState"]
    test_object.to_s.should == NESTED_STORY["Name"]
    test_object.name.should == NESTED_STORY["Name"]
    test_object.children["Child 1"].name.should == CHILD_STORY1["Name"]
  end

  it "should return a rally collection for an array" do
    test_object = RallyAPI::RallyObject.new(@mock_rally, CHILD_STORY2)
    test_object.Tasks.class.name.should == "RallyAPI::RallyCollection"
    test_object.Tasks["Task 4"].State.should == "In-Progress"
  end

  it "should be able to add to a RallyCollection" do
    test_object = RallyAPI::RallyObject.new(@mock_rally, CHILD_STORY2)
    test_object["Tasks"] << {"Name" => "added task to RallyCollection", "_type" => "task"}
    test_object["Tasks"].length.should == 3
  end

end