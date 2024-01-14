#include "IDList.h"

void IDList::addVar(const string name, const string type)
{
    IDs.insert({name, type});
}

bool IDList::existsVar(const string name) const
{
    return IDs.find(name) != IDs.end();
}

void IDList::printVars() const
{
    for (const auto &var: IDs)
    {
        cout << "[Name: " << var.first << ", Type: " << var.second << "]\n";
    }
}

IDList::~IDList()
{
    IDs.clear();
}
