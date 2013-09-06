
/*
 +------------------------------------------------------------------------+
 | Phalcon Framework                                                      |
 +------------------------------------------------------------------------+
 | Copyright (c) 2011-2013 Phalcon Team (http://www.phalconphp.com)       |
 +------------------------------------------------------------------------+
 | This source file is subject to the New BSD License that is bundled     |
 | with this package in the file docs/LICENSE.txt.                        |
 |                                                                        |
 | If you did not receive a copy of the license and are unable to         |
 | obtain it through the world-wide-web, please send an email             |
 | to license@phalconphp.com so we can send you a copy immediately.       |
 +------------------------------------------------------------------------+
 | Authors: Andres Gutierrez <andres@phalconphp.com>                      |
 |          Eduar Carvajal <eduar@phalconphp.com>                         |
 +------------------------------------------------------------------------+
 */

namespace Phalcon;

/**
 * Phalcon\Validation
 *
 * Allows to validate data using validators
 */
class Validation extends Phalcon\DI\Injectable
{
	protected _data;

	protected _entity;

	protected _validators;

	protected _filters;

	protected _messages;

	protected _values;

	/**
	 * Phalcon\Validation constructor
	 *
	 * @param array validators
	 */
	public function __construct(validators=null)
	{

		if typeof validators != "null" {
			if typeof validators != "array" {
				throw new Phalcon\Validation\Exception("Validators must be an array");
			}
			let this->_validators = validators;
		}

		/**
		 * Check for an 'initialize' method
		 */
		if (method_exists(this, "initialize")) {
			this->initialize();
		}
	}

	/**
	 * Validate a set of data according to a set of rules
	 *
	 * @param array|object data
	 * @param object entity
	 * @return Phalcon\Validation\Message\Group
	 */
	public function validate(data=null, entity=null)
	{

		let validators = this->_validators;
		if typeof validators != "array" {
			throw new Phalcon\Validation\Exception("There are no validators to validate");
		}

		/**
		 * Clear pre-calculated values
		 */
		let this->_values = null;

		/**
		 * Implicitly creates a Phalcon\Validation\Message\Group object
		 */
		let messages = new Phalcon\Validation\Message\Group();

		/**
		 * Validation classes can implement the 'beforeValidation' callback
		 */
		if method_exists(this, 'beforeValidation') {
			if this->beforeValidation(data, entity, messages) === false {
				return false;
			}
		}

		let this->_messages = messages;

		if typeof data == "array" {
			let this->_data = data;
		} else {
			if typeof data == "object" {
				let this->_data = data;
			}
		}

		let cancelOnFail = "cancelOnFail";

		for scope in validators {

			if typeof scope != "array" {
				throw new Phalcon\Validation\Exception("The validator scope is not valid");
			}

			let attribute = scope[0],
				validator = scope[1];

			if typeof validator != "object" {
				throw new Phalcon\Validation\Exception("One of the validators is not valid");
			}

			/**
			 * Check if the validation must be canceled if this validator fails
			 */
			if validator->validate(this, attribute) === false {
				if (validator->getOption(cancelOnFail)) {
					break;
				}
			}
		}

		/**
		 * Get the messages generated by the validators
		 */
		let messages = this->_messages;
		if method_exists(this, "afterValidation") {
			this->afterValidation(data, entity, messages);
		}

		return messages;
	}

	/**
	 * Adds a validator to a field
	 *
	 * @param string attribute
	 * @param Phalcon\Validation\ValidatorInterface
	 * @return Phalcon\Validation
	 */
	public function add(attribute, validator)
	{

		if typeof attribute != "string" {
			throw new Phalcon\Validation\Exception("The attribute must be a string");
		}

		if typeof validator != "object" {
			throw new Phalcon\Validation\Exception("The validator must be an object");
		}

		let this->_validators[] = [attribute, validator];
		return this;
	}

	/**
	 * Adds filters to the field
	 *
	 * @param string attribute
	 * @param array|string attribute
	 * @return Phalcon\Validation
	 */
	public function setFilters(attribute, filters)
	{
		let this->_filters[attribute] = filters;
		return this;
	}

	/**
	 * Returns all the filters or a specific one
	 *
	 * @param string attribute
	 * @return mixed
	 */
	public function getFilters(attribute=null)
	{
		let filters = this->_filters;
		if typeof attribute == "string" {
			if fetch attributeFilters, filters[attribute] {
				return attributeFilters;
			}
			return null;
		}
		return filters;
	}

	/**
	 * Returns the validators added to the validation
	 *
	 * @return array
	 */
	public function getValidators()
	{
		return this->_validators;
	}

	/**
	 * Returns the bound entity
	 *
	 * @return object
	 */
	public function getEntity()
	{
		return this->_entity;
	}

	/**
	 * Returns the registered validators
	 *
	 * @return Phalcon\Validation\Message\Group
	 */
	public function getMessages()
	{
		return this->_messages;
	}

	/**
	 * Appends a message to the messages list
	 *
	 * @param Phalcon\Validation\MessageInterface message
	 * @return Phalcon\Validation
	 */
	public function appendMessage(<Phalcon\Validation\MessageInterface> message)
	{
		let messages = this->_messages;
		messages->appendMessage(message);
		return this;
	}

	/**
	 * Assigns the data to an entity
	 * The entity is used to obtain the validation values
	 *
	 * @param string entity
	 * @param string data
	 * @return Phalcon\Validation
	 */
	public function bind(entity, data)
	{
		if typeof entity != "object" {
			throw new Phalcon\Validation\Exception("The entity must be an object");
		}

		if typeof data != "array" {
			if typeof data != "object" {
				throw new Phalcon\Validation\Exception("The data to validate must be an array or object");
			}
		}

		let this->_entity = entity,
			this->_data = data;

		return this;
	}

	/**
	 * Gets the a value to validate in the array/object data source
	 *
	 * @param string attribute
	 * @return mixed
	 */
	public function getValue(attribute)
	{

		let entity = this->_entity;

		/**
		 * If the entity is an object use it to retrieve the values
		 */
		if typeof entity == "object" {
			let method = "get" . attribute;
			if method_exists(entity, method) {
				let value = entity->{method}();
			} else {
				if method_exists(entity, "readAttribute") {
					let value = entity->readAttribute(attribute);
				} else {
					if isset entity->attribute {
						let value = entity->attribute;
					} else {
						let value = null;
					}
				}
			}
			return value;
		}

		let data = this->_data;

		if typeof data != "array" {
			if typeof data != "object" {
				throw new Phalcon_Validation_Exception("There is no data to validate");
			}
		}

		/**
		 * Check if there is a calculated value
		 */
		let values = this->_values;
		if fetch value, values[attribute] {
			return value;
		}

		let value = null;
		if typeof data == "array" {
			if isset data[attribute] {
				let value = data[attribute];
			}
		} else  {
			if typeof data == "object" {
				if isset data->attribute {
					let value = data->attribute;
				}
			}
		}

		if typeof value != "null" {

			let filters = this->_filters;
			if typeof filters == "array" {

				if fetch fieldFilters, filters[attribute] {

					if fieldFilters {

						let dependencyInjector = this->getDI();
						if typeof dependencyInjector != "object" {
							let dependencyInjector = Phalcon\DI::getDefault();
							if typeof dependencyInjector != "object" {
								throw new Phalcon\Validation\Exception("A dependency injector is required to obtain the 'filter' service");
							}
						}

						let filterService = dependencyInjector->getShared("filter");
						if typeof filterService != "object" {
							throw new Phalcon\Validation\Exception("Returned 'filter' service is invalid");
						}

						return filterService->sanitize(value, fieldFilters);
					}
				}
			}

			/**
			 * Cache the calculated value
			 */
			let this->_values[attribute] = value;

			return value;
		}

		return null;
	}

}