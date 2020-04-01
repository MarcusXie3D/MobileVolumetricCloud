// author: Marcus Xie
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateClouds : MonoBehaviour
{
    public Transform cloudPrefab;
    // the size of one chunk of cloud
    public float cloudScale = 17f;
    public float shapeScale = 12f;
    // distribution range of ALL clouds, describing how far they sprawl to the skyline
    public int totalRange = 32;
    // how much chuncks of clouds are fit into 1 unit of area. the higher it is, the more stuffy the clouds look like
    public int density = 6;
    public float height = 10f;
    // if this is set pretty high, cloud chunks vary in vertical position. If this is set to 0, cloud chunks are placed flatly on a plane.
    public float thickness = 4f;
    // determines what proportion of the sky is covered by clouds
    [Range(0f, 1f)]
    public float CoverageRate = 0.16f;
    // uncheck isEditting and modify other parameters, then check it and uncheck it back quickly, or you computer can be stalled a lot
    // make sure this is NOT checked before you build the project
    public bool isEditting = false;

    private int oneSideAmount;

    void Awake()
    {
        Generate();
    }

    void Update()
    {
        // uncheck isEditting and modify other parameters, then check it and uncheck it back quickly, or you computer can be stalled a lot
        // make sure that isEditting is NOT checked before you build the project
        if (isEditting)
        {
            foreach (Transform child in transform)
            {
                GameObject.Destroy(child.gameObject);
            }

            Generate();
        }
    }

    bool OkToPlace (int x, int y)
    {
        float xCoord = (float)x / oneSideAmount * shapeScale;
        float yCoord = (float)y / oneSideAmount * shapeScale;
        float sample = Mathf.PerlinNoise(xCoord, yCoord);
        // determines what proportion of the sky is covered by clouds
        if (sample < CoverageRate)
            return true;
        return false;
    }

    void Generate()
    {
        oneSideAmount = totalRange * density;
        Vector3 position;
        Vector3 scale;
        Random.InitState(42);
        for (int x = 0; x < oneSideAmount; x++)
        {
            for (int y = 0; y < oneSideAmount; y++)
            {
                if (OkToPlace(x, y))
                {
                    Transform cloud = Instantiate(cloudPrefab);
                    position.x = ((float)x / (float)oneSideAmount) * (totalRange * 8) - (totalRange * 4);
                    position.z = ((float)y / (float)oneSideAmount) * (totalRange * 8) - (totalRange * 4);
                    position.y = ((float)Random.Range(-255, 256) / 512f) * thickness + height;
                    float xRand = ((float)Random.Range(-127, 128) / 512f);
                    float zRand = ((float)Random.Range(-127, 128) / 512f);
                    float yRand = Mathf.Min(xRand, zRand);//make the cloud look more flat
                    float scaleRand = ((float)Random.Range(-127, 128) / 512f);
                    float currentScale = cloudScale * (scaleRand + 1f);
                    scale.x = currentScale * (xRand + 1f);
                    scale.z = currentScale * (zRand + 1f);
                    scale.y = currentScale * (yRand + 1f) * 0.8f;// * 0.8f is to make the cloud look more flat
                    cloud.localPosition = position;
                    cloud.localScale = scale;
                    cloud.localRotation = Quaternion.Euler(0, (float)Random.Range(0, 180), 0);
                    // join the newly created cloud into the CloudGroup parent object
                    cloud.SetParent(transform, false);
                    // no need for clouds to cast or receive shadows
                    cloud.GetComponent<Renderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                    cloud.GetComponent<Renderer>().receiveShadows = false;
                }
            }
        }
    }
}
