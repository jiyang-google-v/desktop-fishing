const {contextBridge,ipcRenderer}=require('electron');
contextBridge.exposeInMainWorld('fishing',{
 state:()=>ipcRenderer.invoke('game:state'),cast:()=>ipcRenderer.invoke('game:cast'),reel:()=>ipcRenderer.invoke('game:reel'),add:(id)=>ipcRenderer.invoke('game:aquarium-add',id),remove:(i)=>ipcRenderer.invoke('game:aquarium-remove',i),subscribe:(cb)=>{const fn=(_e,state)=>cb(state);ipcRenderer.on('game:state',fn);return ()=>ipcRenderer.removeListener('game:state',fn)}
});
