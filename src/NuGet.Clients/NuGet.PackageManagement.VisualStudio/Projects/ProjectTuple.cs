// Copyright (c) .NET Foundation. All rights reserved.
// Licensed under the Apache License, Version 2.0. See License.txt in the project root for license information.

using System;
using System.Collections.Generic;
using System.Linq;
using NuGet.Frameworks;
using NuGet.PackageManagement.VisualStudio.Utility;

namespace NuGet.PackageManagement.VisualStudio
{
    public class ProjectTuple : IEquatable<ProjectTuple>
    {
        public NuGetFramework TargetFramework { get; set; }
        public Dictionary<string, ProjectInstalledPackage> Packages { get; internal set; }

        public bool Equals(ProjectTuple other)
        {
            if (other == null)
            {
                return false;
            }

            bool equalsFramework;
            if (TargetFramework != null)
            {
                equalsFramework = TargetFramework.Equals(other.TargetFramework);
            }
            else
            {
                equalsFramework = other.TargetFramework == null;
            }

            bool equalsDict = false;
            if (Packages != null)
            {
                if (other.Packages != null)
                {
                    equalsDict = Packages.Count == other.Packages.Count && !Packages.Except(other.Packages).Any();
                }
            }
            else
            {
                equalsDict = other.Packages == null;
            }

            return equalsFramework && equalsDict;
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as ProjectTuple);
        }

        public override int GetHashCode()
        {
            return TargetFramework.GetHashCode() + 37 * Packages.GetHashCode();
        }
    }
}
