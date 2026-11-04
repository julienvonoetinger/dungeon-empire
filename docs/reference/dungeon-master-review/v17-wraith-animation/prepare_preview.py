from pathlib import Path
out = Path(__file__).resolve().parent
repo = out.parents[3]
source = (repo/'scripts/previews/meshy_master_preview.gd').read_text(encoding='utf-8')
source = source.replace('meshy_master.gd','wraith_master.gd').replace('DURATION := 18.0','DURATION := 6.0')
source = source.replace('Maître du donjon · Animation Meshy 3D','Maître Oculin · Lévitation')
source = source.replace('Modèles Meshy · Animation 3D','Esprit d’ombre · Lévitation · Boucle de 6 secondes')
source = source.replace('camera.size = 8.8','camera.size = 2.4')
source = source.replace('view_slider.min_value = -55','view_slider.min_value = -180').replace('view_slider.max_value = 55','view_slider.max_value = 180')
source = source.replace('clampf(value,-55.0,55.0)','clampf(value,-180.0,180.0)')
source = source.replace('set_time(minf(clock+delta*speed,DURATION))\n\t\tif clock >= DURATION: set_paused(true)','set_time(fposmod(clock+delta*speed,DURATION))')
source = source.replace('Vector3(sin(angle)*9.0,0.4,cos(angle)*9.0)','Vector3(sin(angle)*5.0,1.15,cos(angle)*5.0)')
source = source.replace('camera.look_at(Vector3.ZERO)','camera.look_at(Vector3(0,0.85,0))')
source = source[:source.index('\tvar phase := "Présence"')] + '\tstatus.text = "Lévitation · %.1f / 6 s" % clock\n'
(repo/'scripts/previews/wraith_master_preview.gd').write_text(source,encoding='utf-8')
scene = (repo/'scenes/previews/MeshyMasterPreview.tscn').read_text(encoding='utf-8').replace('meshy_master_preview.gd','wraith_master_preview.gd').replace('MeshyMasterPreview','WraithMasterPreview')
(repo/'scenes/previews/WraithMasterPreview.tscn').write_text(scene,encoding='utf-8')
