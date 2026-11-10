/** Rugby union numbering; flankers use the conventional 6 blindside / 7 openside. */
export const positions=['','Pilar izquierdo','Talonador','Pilar derecho','Segunda línea I','Segunda línea II','Ala lado ciego','Ala lado abierto','Número ocho','Medio melé','Apertura','Ala izquierdo','Centro interior','Centro exterior','Ala derecho','Zaguero'];

/** Schematic seen from behind the team, attacking upwards, matching the reference. */
export const formation:ReadonlyArray<{number:number;x:number;y:number}>=[
 {number:1,x:68,y:17},{number:2,x:78,y:17},{number:3,x:88,y:17},
 {number:4,x:73,y:29},{number:5,x:83,y:29},
 {number:6,x:94,y:38},{number:7,x:62,y:38},{number:8,x:78,y:46},
 {number:9,x:88,y:66},{number:10,x:67,y:81},
 {number:11,x:12,y:108},{number:12,x:47,y:92},{number:13,x:29,y:101},
 {number:14,x:108,y:92},{number:15,x:65,y:113},
];

/** Rotate the reference onto the existing horizontal pitch: attack towards x=0. */
export const pitchFormation=formation.map(({number,x,y})=>({
 number,x:10+(y-17)*.72,y:65-x*.5,
}));
