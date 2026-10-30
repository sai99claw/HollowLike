"""Regress real cut-grid failure modes without requiring the image model."""
import importlib.util
from pathlib import Path
import unittest,json
from PIL import Image,ImageDraw
import numpy as np
spec=importlib.util.spec_from_file_location('atlas',Path(__file__).resolve().parents[1]/'scripts/prepare_monster_art_v36.py')
atlas=importlib.util.module_from_spec(spec);spec.loader.exec_module(atlas)
class Extraction(unittest.TestCase):
 def test_source_layout_guard(self):
  with self.assertRaises(ValueError):atlas.actor_pieces(Image.new('RGBA',(1200,500)),5)
 def test_actor_row_remap_and_neighbor_removal(self):
  image=Image.new('RGBA',(600,1000));draw=ImageDraw.Draw(image)
  for row in range(10):
   for col in range(6):
    draw.rectangle((col*100+30,row*100+25,col*100+70,row*100+80),fill=(row*20,col*30,90,255))
    draw.rectangle((col*100+1,row*100+1,col*100+5,row*100+5),fill=(255,0,0,255))
  pieces=atlas.actor_pieces(image,5)
  self.assertEqual(len(pieces),5)
  self.assertEqual(len(pieces[0]),12)
  self.assertEqual(pieces[1][6].getpixel((20,20))[:3],(60,0,90))
  self.assertLess(pieces[0][0].width,60)
 def test_projectile_core_straddles_nominal_cell(self):
  image=Image.new('RGBA',(800,300));draw=ImageDraw.Draw(image)
  # The body nose extends past each nominal cell. Cropping first would lose it.
  for col in range(8):
   draw.polygon([(col*100+55,35),(col*100+115,50),(col*100+55,65)],fill=(0,200,255,255))
   for row in [1,2]:draw.ellipse((col*100+35,row*100+30,col*100+65,row*100+65),fill=(90,200,90,255))
  pieces=atlas.projectile_pieces(image,3)
  self.assertGreater(pieces[0][2].width,55)
  self.assertGreater(np.asarray(pieces[0][2])[:,:,3].sum(),100000)
 def test_effect_dissolve_keeps_multiple_authored_pieces(self):
  image=Image.new('RGBA',(800,300));draw=ImageDraw.Draw(image)
  for col in range(8):
   for row in range(3):
    draw.rectangle((col*100+25,row*100+35,col*100+40,row*100+55),fill=(255,200,0,255))
    if row==1:draw.rectangle((col*100+65,row*100+35,col*100+80,row*100+55),fill=(255,200,0,255))
  pieces=atlas.projectile_pieces(image,3)
  self.assertGreater(pieces[1][4].width,50)
 def test_runtime_cells_have_transparent_guard_border(self):
  root=Path(__file__).resolve().parents[1]/'assets/v36/monsters'
  count=0
  for biome in ['underground','trunk','sky']:
   data=json.loads((root/(biome+'-runtime.json')).read_text())
   for sheet in data['sheets'].values():
    image=Image.open(root/sheet['path']).convert('RGBA')
    for frame in sheet['frames']:
     x,y,w,h=frame['rect'];alpha=np.asarray(image.crop((x,y,x+w,y+h)))[:,:,3]
     self.assertEqual(int(alpha[:3].max()),0)
     self.assertEqual(int(alpha[-3:].max()),0)
     self.assertEqual(int(alpha[:,:3].max()),0)
     self.assertEqual(int(alpha[:,-3:].max()),0)
     self.assertGreater(int(alpha.max()),0);count+=1
  self.assertEqual(count,468)
if __name__=='__main__':unittest.main()
