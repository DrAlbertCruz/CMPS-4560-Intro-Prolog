# Lab 1: Introduction to SWI Prolog

# Introduction

## Requirements
* `swipl`. SWI Prolog is an inference engine for Prolog. Note that its syntax is slightly different from `gprolog`.
* `familytree.pl` in this repository if you need to brush up on Prolog.

## Prerequisites
* Some familiarity with Prolog (from 3560). Prolog is an interpreted, functional programming language. Because it is interpreted, you will create your code and run it in a Prolog interpreter. Prolog is specifically for inference and knowledge resolution, so we call the interpreter an 'inference engine'. I/O is carried out in the form of sentences that are posed to the inference engine, which uses backward chaining to determine the truthiness of the sentence.
* Brush up on first-order/predicate logic from 2120
* Solve the Farmer, Wolf, Goat and Cabbage problem by hand

## Objectives

* Familiarize yourself with SWI Prolog
* Develop a reflex agent with state
* Implement the environment and actions for the Farmer, Wolf, Goat and Cabbage problem
* Apply the agent to solve the problem

## Background
In today’s lab we will use Prolog to solve the Farmer, Wolf, Goat and Cabbage Problem. The problem statement is as follows:

> A farmer wants to cross a river from the west side to the east side and take a wolf, a goat, and a head of cabbage along with him. There is a boat that can fit himself plus one of his "companions." If the wolf and the goat are alone on one shore, the wolf will eat the goat. If the goat and the cabbage are alone on the shore, the goat will eat the cabbage. How can the farmer bring the wolf, the goat, and the cabbage across the river?

Note that the farmer can travel on the boat by himself, but his "companions" cannot make trips by themselves (i.e., they must accompany him). The solution to this problem is as follows:

* Farmer takes Goat across (leaving Wolf and Cabbage behind)
* Farmer returns alone
* Farmer takes Wolf across
* Farmer returns with Goat
* Farmer takes Cabbage across
* Farmer returns alone
* Farmer takes Goat across

Your task is to develop the predicates that define the environment, that actions that can be taken and the agent function to solve the problem.

# Approach

The approach is divided into two sections: Part 0 if you are new to Prolog, or need a refresher on it, and Part 1. Part 1 is the lab.

## Part 0 - Inference with Prolog

This section provides background for the inner workings of Prolog, and the workflow for developing a Prolog 'program'. The prolog source file (`.pl` file) included in this repository has some rules defining kinship and some facts defining marriage and children in House Stark from Game of Thrones. Recall that predicate logic focuses heavily on relations between variables rather than the instance of a variable itself. Prolog code consists of predicates, constants and variables:

* Predicate: the first part of a Prolog fact or rule. E.g., in `ate(albert, waffles).`, ate is the predicate. 
* Constant: a clause in the interior of a Prolog predicate. E.g., in `ate(albert, waffles).`, both albert and waffles are constants
* Variable: often used in Prolog queries, indicated by an upper case letter. E.g., in `ate(albert, X)`., Prolog would attempt to find predicate that is true for some X.

On the department server you can start the Prolog CLI with the command `swipl`:

```shell
$ swipl
```

The following lets you know that the Prolog CLI is ready to accept sentences:

```prolog
?- 
```

Once loaded, files can be loaded into your Prolog environment with:

```prolog
?- consult( 'familytree.pl' ).
```

*Note that Prolog sentences must be terminated with a period!* The following prompt:

```prolog
?- halt.
```

Terminates the Prolog CLI. If you used `gprolog` before, you had to use the `reconsult` predicate whenever changes were made to Prolog source files. In `swipl`, `consult` will wipe any predicates that were previously loaded by the old version of the source file. I.e., if you make changes to a `.pl` file, just `consult` it again. Get back into the Prolog CLI, and make sure `familytree.pl` has been consulted before continuing. 

Getting back to the kinship example with House Stark, if you enter:

```prolog
?- man(eddard).
```

You should get:

```prolog
?- man(eddard).
	true.
```

Looking at the source code there is no predicate declaring that `man(eddard).`. However, there is a rule that defines `man(X) :- husband(X,_)`. The `_` operator is used for facts or queries where the value of a constant does not matter. In prolog, the consequent is on the LHS and the antecedent is on the RHS. Thus, if `husband(X,_)`, then `man(X)` is true. To determine the truth of the antecedent, prolog carries out the backward chaining algorithm we learned in 3560. It does this by visiting each clause left-to-right in a depth-first-search fashion. Recall that `X` is a variable because the first letter of the identifier starts with a capital letter, so prolog will try all constants that be substituted to satisfy `husband(X,_)`. Note that `eddard` is `husband( eddard, catelyn_tully )` in the source file. Thus, eddard must be a man. As an exercise, using the base code, define more relationships: grandmother, woman, wife, daughter, son, brother, sister. Investigate the following:

1. What happens if you add more than one definition of a single relationship?
1. Are more facts needed to define all possible relationships?

Don't preoccupy yourself too much with this, as we need to move on to the core content of the lab. *Caution: The rest of this lab assumes you are using swipl and not gprolog.*

# Part 1 - Farmer, goat, cabbage and wolf problem

## Necessary SWI-Prolog Commands

Before we can solve this problem, we should go over some advanced SWI commands.

* `assertz`: Used to insert facts into the Prolog database. `assertz` is a single argument function that, after execution, will insert the passed argument into the knowledgebase. For example:

```prolog
?- female('Jane').
	false.
?- assertz(female('Jane')).
	true.
?- female('Jane').
	true.
```

* `dynamic`: There is a catch to the above. A predicate cannot be `assertz`'d if it was not declared as `dynamic` in a source file that was consulted prior to the assertion. For example, for the above example to work, a source code file should have contained:

```prolog
:- dynamic female/1.
...
```

In the above code, the predicate `female(...)` can now be asserted. The `/1` indicates that single-argument `female` predicates are dynamic. Thus, `assertz(female(a,b)).` would result in an error, unless `:- dynamic female/2.` was also included.

* `listing`: Used to check state of facts rules.

## Problem setup

The following two subsections are just one possible solution to this problem. You may want to think about this problem on your own, as the following section contains spoilers/hints. Prolog has a built in DFS which can explore possible solutions to the problem. We just need to frame a query such that Prolog will explore the state space, determining if a move is valid at each step. There will be four variables which take on {w,e} indicating whether or not the farmer or his companions have visited the space:

```prolog
visited( w,e,e,w ).
```

By convention, let the constants represent the farmer, the wolf, the goat and the cabbage in that order. Note that this is an illegal state, as the wolf will eat the goat because they are both on the east side and not supervised by the farmer. We want SWI to visit the states automatically based on a query, as we do not want to write down all visited states ourselves as static facts. We should frame our search like this:

```prolog
solve(w,w,w,w).
solve(A,B,C,D) :- change_state(A,B,C,D,W,X,Y,Z),
 <check if illegal>,
 <check if already visited>,
 assertz( visited( W,X,Y,Z ) ),
 solve( W,X,Y,Z ). 
```

Note that the first sentence is the ground term. We will frame this problem recursively. Using `assertz` will keep track of what states we have visited by dynamically inserting facts into Prolog's database. This way, we can keep track of what states we have visited. After the search is finished, we can look up what states DFS has visited with `listing`. Because each clause is visited in order, if <check if illegal> is false, the rest of the rule will not fire, so rules which result in invalid moves will not be pushed to the knowledgebase. In the following, we step through each clause in depth.

## Defining the actions

How do you get Prolog to explore a state? Prolog will automatically explore all possible movements if you query solve with variables. It will search all possibilities (remember the from 3560?), so the task for us is defining how Prolog can "move". Consider what is happening: a constant is switching from west to east. It should be framed like this:

```prolog
change_state( <current state vars> , <next state vars> ).
```

By convention, let us say that the state consists of the farmer first, then the wolf, then the goat and finally the cabbage. Thus:

```prolog
change_state(w,X,Y,Z,e,X,Y,Z).
change_state(e,X,Y,Z,w,X,Y,Z).
```

Allows the farmer to move west to east and vise versa. The first four arguments are for the starting state, and the second four arguments are for the end state of the action. Note that X, Y and Z are in the same position in the four-tuple, thus they will not move. Only the farmer (in the first position of the four tuple) changes from one side to the other. Pay attention to the upper case letter: this means that we do not care what the other constants are, as only the farmer is moving. The "companions" must travel with the farmer, so this would be a fact allowing the farmer and wolf traveling together:

```prolog
change_state(w,w,X,Y,e,e,X,Y). 
```

Repeat this for all possible actions. The farmer can only take one "companion" with him in the boat at once. Define all the rules for movement before moving on to the next section.

## Defining legality of actions

Now consider the code to check if a state (e.g., w,w,w,w or w,e,e,w) is legal or illegal. There are many legal moves, so we should instead focus on defining illegal states. An example:

```prolog
illegal(w,e,e,_). 
```

This makes it illegal to have the wolf and the goat on the east side together (the second position is the wolf; the third, the goat). Thus, this state is illegal because the wolf would eat the goat. Complete all illegal states before moving on.

## Agent function that searches for legal moves

Once you've completed the sections above you should be able perform a search within the space. The full solve command is as follows:

```prolog
solve(w,w,w,w).
solve(X,Y,Z,W) :- change_state(X,Y,Z,W,X1,Y1,Z1,W1),
 \+ illegal(X1,Y1,Z1,W1),
 \+ clause(visited(X1,Y1,Z1,W1),_),
 assertz(visited(X1,Y1,Z1,W1)),
 solve(X1,Y1,Z1,W1). 
```

`\+` is a negation in prolog. `clause(...,_)` prevents the agent from visiting past states. If you completed the lab properly call `solve(e,e,e,e)` then `listing(visited)`. to see if SWI discovered the solution.
