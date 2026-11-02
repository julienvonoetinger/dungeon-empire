// The room and the camera never rotate. Only the treasure's ground layout
// turns, so the fronts of both chests point toward the actual entrance.
const inward={N:[0,1],E:[-1,0],S:[0,-1],W:[1,0]};
const facing={N:"north",E:"east",S:"south",W:"west"};
const items=[
 {type:"bank",u:0,v:.28,width:188},
 {type:"open",u:-.41,v:-.20,scale:1.09},
 {type:"closed",u:.39,v:-.11,scale:.91},
 {type:"tied",u:-.63,v:.30,width:51},
 {type:"open-bag",u:-.49,v:-.57,width:48},
 {type:"tied",u:.50,v:.48,width:49},
 {type:"tied",u:.68,v:.13,width:45},
 {type:"open-bag",u:.68,v:-.32,width:49}
];
function turn(side,u,v){
 const [ix,iy]=inward[side];return [-iy*u+ix*v,ix*u+iy*v];
}
module.exports={inward,facing,items,turn};
