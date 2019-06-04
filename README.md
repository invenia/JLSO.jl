# JLSO

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/JLSO.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://invenia.github.io/JLSO.jl/dev)
[![Build Status](https://travis-ci.com/invenia/JLSO.jl.svg?branch=master)](https://travis-ci.com/invenia/JLSO.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/invenia/JLSO.jl?svg=true)](https://ci.appveyor.com/project/invenia/JLSO-jl)
[![Codecov](https://codecov.io/gh/invenia/JLSO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/JLSO.jl)

JLSO is a storage container for serialized Julia objects.
At the top-level it is a BSON file,
where it stores metadata about the system it was created on as well as a collection of objects (the actual data).

Depending on configuration, those objects may themselves be stored as BSON sub-documents,
or in the native Julia serialization format (default).
It is fast and efficient to load just single objects out of a larger file that contains many objects.

The metadata (always stored in BSON) includes the Julia version and the versions of all packages installed.
This means in the worst case you can install everything again and replicate your system.
(Extreme worst case scenario, using a BSON reader from another programming language).

Note: If the amount of data you have to store is very small, relative to the metadata about your environment, then it is a pretty suboptimal format.
Then is is a pretty suboptimal format.
