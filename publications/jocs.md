---
title: "Decapodes: A diagrammatic tool for representing, composing, and computing spatialized partial differential equations"
author: "Luke Morris, Andrew Baas, Jesus Arias, Maia Gatlin, Evan Patterson, James P. Fairbanks"
image: https://ars.els-cdn.com/content/image/1-s2.0-S1877750324001388-gr1_lrg.jpg
type: "article"
year: "2024"
publication: "Journal of Computational Science"
preprint: "https://arxiv.org/abs/2401.17432"
doi: "https://doi.org/10.1016/j.jocs.2024.102345"
materials: ""
toc: false
categories:
    - Multiphysics
    - Discrete exterior calculus
    - Numerical methods
    - Operad algebras
---

## Abstract

We present Decapodes, a diagrammatic tool for representing, composing, and solving partial differential equations. Decapodes provides an intuitive diagrammatic representation of the relationships between variables in a system of equations, a method for composing systems of partial differential equations using an operad of wiring diagrams, and an algorithm for deriving solvers using hypergraphs and string diagrams. The string diagrams are in turn compiled into executable programs using the techniques of categorical data migration, graph traversal, and the discrete exterior calculus. The generated solvers produce numerical solutions consistent with state-of-the-art open source tools as demonstrated by benchmark comparisons with SU2. These numerical experiments demonstrate the feasibility of this approach to multiphysics simulation and identify areas requiring further development.

## Links

- [Journal](https://www.sciencedirect.com/science/article/pii/S1877750324001388)
- [Code](https://github.com/AlgebraicJulia/Decapodes.jl)
- [Docs](https://algebraicjulia.github.io/Decapodes.jl/dev/)
