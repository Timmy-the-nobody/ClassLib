-- Here we create a new class that inherits from BaseClass
Person = ClassLib.Inherit(BaseClass)

-- Here we add a constructor to the class, which is called when we call `Class()` to create a new instance, with `self` being the instance
function Person:Constructor(sName)
    self.name = sName
end

-- Here we add a destructor to the class, which is called when we call `instance:Destroy()` to destroy an instance, with `self` being the instance
function Person:Destructor()
    print("Person "..self.name.." is being destroyed")
end

-- Here we create some instances of the Person class
local ePerson = Person("John")
local ePerson2 = Person("Jane")
local ePerson3 = Person("Jack")

-- Here we clone an instance, and change it's `name` property
local ePerson4 = ePerson3:Clone()
ePerson4.name = "Jill"

-- Here we print the instance ID and it's `name` property
print("ePerson3:GetID():", ePerson3:GetID(), "ePerson3.name:", ePerson3.name)

-- Here we get the class of the instance, and compare it with `Employee`, this will return true
print("ePerson4:GetClass() == Employee:", ePerson4:GetClass() == Employee)

-- Here we destroy an instance, after that we can't index it anymore, and will not be retrievable by the class static functions
ePerson2:Destroy()

------------------------------------------------------------------------------------------

-- Here we loop through all valid instances of the Person class, be carefull with this, the key will not be the same as the instance's ID (which is stored in the `id` property)
for _, oPerson in ipairs(Person.GetAll()) do
    print(oPerson.name.." [class ID: "..oPerson:GetID().."]")
end

-- Here we print the amount of valid instances of the Person class, will return 3 since we destroyed one
print(Person.GetCount())

-- Here we get a specific instance by it's ID and print it's `name` property, in this case it'll print "Jill"
print(Person.GetByID(4).name)

-- Here we print the name of the class from which the Person class inherits
print(Person.GetParentClass())

-- Here we print the amount of classes from which the Person class inherits, in this case it'll print 1 since it only inherits from BaseClass
print("#Person.GetParentClasses()", #Person.GetParentClasses())

-- Here we print if a class inherit from another one (in this case we check if Person inherits from BaseClass), this will check from parent parents as well
print("Person.IsChildOf(BaseClass)", Person.IsChildOf(BaseClass))

------------------------------------------------------------------------------------------

-- Here we create a new class that inherits from Person
Employee = ClassLib.Inherit(Person)

function Employee:Constructor(sName)
    -- Here we call the constructor of the super class, which is Person
    self:Super().Constructor(self, sName)

    -- Here we add a new property to the Employee instance
    self.salary = 1000
end

-- Here we create a new instance of the Employee class
local eEmployee = Employee("Janett")

-- Here we print the amount of classes from which the Person class inherits, in this case it'll print 2 since it inherits from Person, and Person inherits from BaseClass
print("#Employee.GetParentClasses()", #Employee.GetParentClasses())

-- print(NanosTable.Dump(Person))
print(#Person.GetAll())