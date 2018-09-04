%	CALIFORNIA STATE UNIVERSITY, BAKERSFIELD
%	CMPS 456 ADVANCED AI 
%	LAB 1: INTRODUCTION TO PROLOG AND KINSHIP
%	Based on (Quinlan 90). Family tree and kinship of
% 	House Stark
%
%	Version 2, updated 4/1/15

husband( eddard, catelyn_tully ).
husband( edwyle, marna_locke ).
husband( rickard, lyarra ).
husband( robb, jeyne_westerling ).
husband( tyrion_lannister, sansa ).
husband( william, melantha_blackwood ).
husband( william, lyanne_glover ).
husband( benedict_rogers, jocelyn ).
husband( beron, lorra_royce ).
husband( rodrik, arya_flint ).

parent( catelyn_tully, robb ).
parent( catelyn_tully, sansa ).
parent( eddard, robb ).
parent( eddard, sansa ).
parent( edwyle, rickard ).
parent( marna_locke, rickard ).
parent( rickard, eddard ).
parent( lyarra, eddard ).
parent( beron, william ).
parent( beron, rodrik ).
parent( lorra_royce, william ).
parent( lorra_royce, rodrik ).
parent( william, edwyle ).
parent( william, jocelyn ).
parent( melantha_blackwood, edwyle ).
parent( melantha_blackwood, jocelyn ).
parent( rodrik, lyarra ).
parent( arya_flint, lyarra ).



parent( rodrik, lyarra ).

/* Relationships */

grandparent(X,Y) :- parent(X,Z),parent(Z,Y).
man(X) :- husband(X,_).
father(X,Y) :- parent(X,Y),man(X).
mother(X,Y) :- parent(X,Y), \+ man(X).
grandfather(X,Y) :- father(X,Z), father(Z,Y).
grandfather(X,Y) :- father(X,Z), mother(Z,Y).