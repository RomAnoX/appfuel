module AppfuelHelpers
  def allow_const_defined_as_true(mod, name)
    allow_const_defined(mod, name, true)
  end

  def allow_const_defined_as_false(mod, name)
    allow_const_defined(mod, name, false)
  end

  def allow_const_defined(mod, name, result)
    allow(mod).to receive(:const_defined?).with(name) { result }
  end

  def allow_const_get(mod, name, result)
    allow(mod).to receive(:const_get).with(name) { result }
  end

  def build_container(data = {})
    container = Dry::Container.new
    data.each {|key, value| container.register(key, value)}
    container
  end

  def allow_type(name, type)
    allow(Types).to receive(:key?).with(name) { true }
    allow(Types).to receive(:[]).with(name) { type }
    type
  end

  def allow_domain_type(name, type)
    basename = name.to_s.split('.').last
    allow_type(name, type)
    allow(type).to receive(:domain_basename).with(no_args) { basename }
    type
  end

  def allow_db_type(name, type)
    allow(Types::Db).to receive(:key?).with(name) { true }
    allow(Types::Db).to receive(:[]).with(name) { type }
  end

  def allow_db_column_names(db_class, cols)
    allow(db_class).to receive(:column_names).with(no_args) { cols }
  end

  def allow_db_entity_attributes(db_class, hash)
    allow(db_class).to receive(:entity_attributes).with(no_args) { hash }
  end

  def mock_db_class(name, cols = [])
    db_class = class_double(Appfuel::DbModel)
    allow_db_type(name, db_class)
    allow_db_column_names(db_class, cols)
    db_class
  end

  def register_type(name, object)
    Dry::Types.container.register(name, object)
  end

  def type(name)
    Types[name]
  end

  def create_type(name, data = {})
    type(name)[data]
  end

  def create_criteria(domain, opts = {})
    Appfuel::Criteria.new(domain, opts)
  end

  def create_pager(data = {})
    Appfuel::Pagination::Request.new(data)
  end

  def undefined
    Types::Undefined
  end

  def undefined?(obj)
    obj == undefined
  end

  def entity_class_double
    class_double(Appfuel::Domain::Entity)
  end

  def entity_instance_double
    instance_double(Appfuel::Domain::Entity)
  end

  def db_model_instance_double
    instance_double(Appfuel::DbModel)
  end

  def db_model_class_double
    class_double(Appfuel::DbModel)
  end
end
