using System;
using UnityEditor;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HologramShaderUI : ShaderGUI
{
    Material _material;
    MaterialProperty[] _props;
    MaterialEditor _materialEditor;

    private MaterialProperty Brightness = null;

    void AssignProperties()
    {
        Brightness = FindProperty("_Brightness", _props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

        _material = materialEditor.target as Material;
        _props = properties;
        _materialEditor = materialEditor;

        AssignProperties();

        Layout.Initialize(_material);
        EditorGUILayout.BeginHorizontal();
        GUILayout.Space(-7);
        EditorGUILayout.BeginVertical();
        EditorGUI.BeginChangeCheck();

        DrawGUI();

        EditorGUILayout.EndVertical();
        GUILayout.Space(1);
        EditorGUILayout.EndHorizontal();
    }

    void DrawGUI()
    {
        DrawScanLinesSettings();
    }

    void DrawScanLinesSettings()
    {
        GUILayout.Space(-3);
        GUILayout.Label("Scanlines", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;

        bool toggle = Array.IndexOf(_material.shaderKeywords, "_SCAN_ON") != -1;
        EditorGUI.BeginChangeCheck();
        toggle = EditorGUILayout.Toggle("Enable", toggle);

        if (EditorGUI.EndChangeCheck())
        {
            if (toggle)
                _material.EnableKeyword("_SCAN_ON");
            else
                _material.DisableKeyword("_SCAN_ON");
        }
    }
}
