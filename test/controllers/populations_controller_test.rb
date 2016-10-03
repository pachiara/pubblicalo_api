require 'test_helper'

class PopulationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @population = populations(:one)
  end

  test "should get index" do
    get populations_url
    assert_response :success
  end

  test "should get new" do
    get new_population_url
    assert_response :success
  end

  test "should create population" do
    assert_difference('Population.count') do
      post populations_url, params: { population: { code: @population.code, people: @population.people, region: @population.region, year: @population.year } }
    end

    assert_redirected_to population_url(Population.last)
  end

  test "should show population" do
    get population_url(@population)
    assert_response :success
  end

  test "should get edit" do
    get edit_population_url(@population)
    assert_response :success
  end

  test "should update population" do
    patch population_url(@population), params: { population: { code: @population.code, people: @population.people, region: @population.region, year: @population.year } }
    assert_redirected_to population_url(@population)
  end

  test "should destroy population" do
    assert_difference('Population.count', -1) do
      delete population_url(@population)
    end

    assert_redirected_to populations_url
  end
end
