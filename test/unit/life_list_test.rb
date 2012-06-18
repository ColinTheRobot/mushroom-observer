# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../boot.rb')

class LifeListTest < UnitTestCase

  def katrinas_species
    ['Conocybe filaris']
  end

  def rolfs_species
    [
      'Agaricus campestras', # these are not synonymized
      'Agaricus campestris',
      'Agaricus campestros',
      'Agaricus campestrus',
      'Coprinus comatus',
      'Strobilurus diminutivus',
    ]
  end

  def genera(species)
    species.map {|name| name.split(' ', 2).first}.uniq
  end

  def test_life_list_for_site
    data = LifeList::ForSite.new
    all_species = (rolfs_species + katrinas_species).sort
    all_genera = genera(all_species)
    assert_equal(all_genera, data.genera)
    assert_equal(all_species, data.species)
  end

  def test_life_list_for_users
    data = LifeList::ForUser.new(@mary)
    assert_equal(0, data.num_genera)
    assert_equal(0, data.num_species)
    assert_equal([], data.genera)
    assert_equal([], data.species)

    data = LifeList::ForUser.new(@katrina)
    assert_equal(1, data.num_genera)
    assert_equal(1, data.num_species)
    assert_equal(genera(katrinas_species), data.genera)
    assert_equal(katrinas_species, data.species)

    data = LifeList::ForUser.new(@rolf)
    assert_equal(3, data.num_genera)
    assert_equal(6, data.num_species)
    assert_equal(genera(rolfs_species), data.genera)
    assert_equal(rolfs_species, data.species)

    User.current = @dick
    Observation.create!(:name => names(:agaricus))
    assert_names_equal(names(:agaricus), Observation.last.name)
    assert_users_equal(@dick, Observation.last.user)
    data = LifeList::ForUser.new(@dick)
    assert_equal(0, data.num_species)

    Observation.create!(:name => names(:lactarius_kuehneri))
    data = LifeList::ForUser.new(@dick)
    assert_equal(['Lactarius'], data.genera)
    assert_equal(['Lactarius alpinus'], data.species)

    Observation.create!(:name => names(:lactarius_subalpinus))
    Observation.create!(:name => names(:lactarius_alpinus))
    data = LifeList::ForUser.new(@dick)
    assert_equal(['Lactarius'], data.genera)
    assert_equal(['Lactarius alpinus'], data.species)
  end

  def test_life_list_for_users
    boletes = projects(:bolete_project)
    data = LifeList::ForProject.new(boletes)
    assert_equal(0, data.num_genera)
    assert_equal(0, data.num_species)
    assert_equal([], data.genera)
    assert_equal([], data.species)

    obs = observations(:coprinus_comatus_obs)
    boletes.observations << obs
    data = LifeList::ForProject.new(boletes)
    assert_equal(1, data.num_genera)
    assert_equal(1, data.num_species)
    assert_equal(['Coprinus'], data.genera)
    assert_equal(['Coprinus comatus'], data.species)
  end
end
