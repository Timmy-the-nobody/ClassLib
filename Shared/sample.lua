-- Here we create a new class that inherits from BaseClass
Person = BaseClassEx.Inherit("Person") -- ClassLib.Inherit(BaseClass)

-- Here we add a constructor to the class, which is called when we call `Class()` to create a new instance, with `self` being the instance
function Person:Constructor(sLabel)
    self:SetLabel(sLabel)
end

-- Here we add a destructor to the class, which is called when we call `instance:Destroy()` to destroy an instance, with `self` being the instance
function Person:Destructor()
    print("Person ["..self:GetLabel().."] `Destructor` called")
end

-- Here we create some instances of the Person class
local ePerson = Person("John")
local ePerson2 = Person("Jane")
local ePerson3 = Person("Jack")

-- Here we clone an instance, and change it's `label` property
local ePerson4 = ePerson3:Clone()
ePerson4:SetLabel("Jill")

-- Here we print the instance ID and it's `label` property
print("ePerson3:GetID():", ePerson3:GetID(), "ePerson3.name:", ePerson3:GetLabel())

-- Here we get the class of the instance, and compare it with `Employee`, this will return true
print("ePerson4:GetClass() == Employee:", ePerson4:GetClass() == Employee)

-- Here we destroy an instance, after that we can't index it anymore, and will not be retrievable by the class static functions

Timer.SetTimeout(function()
    print(ePerson2:GetLabel(), "is valid?", ePerson2:IsValid())
    ePerson2:Destroy()
    print(ePerson2:GetLabel(), "is valid?", ePerson2:IsValid())

    -- ePerson2:SetNWValue("foo", "bar")
    -- print("ePerson2:GetNWValue", ePerson2:GetNWValue("foo"))
end, 1000)

------------------------------------------------------------------------------------------

-- Here we loop through all valid instances of the Person class, be carefull with this, the key will not be the same as the instance's ID (which is stored in the `id` property)
for _, oPerson in ipairs(Person.GetAll()) do
    print(oPerson:GetLabel().." [class ID: "..oPerson:GetID().."]")
end

-- Here we print the amount of valid instances of the Person class, will return 3 since we destroyed one
print(Person.GetCount())

-- Here we get a specific instance by it's ID and print it's `label` property, in this case it'll print "Jill"
print(Person.GetByID(4):GetLabel())

-- Here we print the name of the class from which the Person class inherits
print(ClassLib.GetClassName(Person.GetParentClass()))

-- Here we print the amount of classes from which the Person class inherits, in this case it'll print 1 since it only inherits from BaseClass
print("#Person.GetAllParentClasses()", #Person.GetAllParentClasses())

-- Here we print if a class inherit from another one (in this case we check if Person inherits from BaseClass), this will check from parent parents as well
print("Person.IsChildOf(BaseClass)", Person.IsChildOf(BaseClass))

------------------------------------------------------------------------------------------

-- Here we create a new class that inherits from Person
Employee = Person.Inherit("Employee")

function Employee:Constructor(sLabel)
    -- Here we call the constructor of the super class, which is Person
    self:Super().Constructor(self, sLabel)

    -- Here we add a new property to the Employee instance
    self.salary = 1000
end

-- Here we create a new instance of the Employee class
local eEmployee = Employee("Janett")



-- Here we print the amount of classes from which the Person class inherits, in this case it'll print 2 since it inherits from Person, and Person inherits from BaseClass
Timer.SetTimeout(function()
    -- print("#Employee.GetAllParentClasses()", Employee.GetAllParentClasses()[2] == BaseClass)

    -- -- print(NanosTable.Dump(Person))
    -- print(#Person.GetAll())
    -- print(ClassLib.GetClassName(eEmployee))
    -- print("test", eEmployee:GetClassName())
    -- print(NanosTable.Dump(eEmployee))

    -- print("---------", ePerson4:GetLabel())
    -- print("---------", ePerson4:GetLabel())
end, 2000)

Timer.SetTimeout(function()
    print("\n\n-----------------------------")

    -- Subscribe/call/unsubscribe to events on the instance
    local some_callback = ePerson3:Subscribe("Something", function(...)
        print(...) -- foo bar
    end)

    ePerson3:Call("Something", "foo", "bar")
    ePerson3:Unsubscribe("Something", some_callback)

    -- Subscribe/call/unsubscribe to events on the class (will also trigger events with the same name on the instances that listen to it)
    Person.ClassSubscribe("Something", function(...)
        local tArgs = {...}
        print(tArgs[1]) -- foo
        print(tArgs[2]) -- bar
    end)

    Person.ClassCall("Something", "foo", "bar")
    Person.ClassUnsubscribe("Something")

    print("-----------------------------")
end, 1500)