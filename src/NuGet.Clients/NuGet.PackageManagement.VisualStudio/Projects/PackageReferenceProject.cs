// Copyright (c) .NET Foundation. All rights reserved.
// Licensed under the Apache License, Version 2.0. See License.txt in the project root for license information.

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.VisualStudio.Threading;
using NuGet.Common;
using NuGet.Frameworks;
using NuGet.LibraryModel;
using NuGet.PackageManagement.VisualStudio.Utility;
using NuGet.Packaging;
using NuGet.ProjectManagement;
using NuGet.ProjectManagement.Projects;
using NuGet.ProjectModel;

namespace NuGet.PackageManagement.VisualStudio
{
    /// <summary>
    /// An implementation of <see cref="NuGetProject"/> that interfaces with VS project APIs to coordinate
    /// packages in a package reference style project.
    /// </summary>
    public abstract class PackageReferenceProject : BuildIntegratedNuGetProject
    {
        private protected DateTime _lastTimeAssetsModified;
        private WeakReference<IList<LockFileTarget>> _lastLockFileTargets;
        //private ObjectCache _transitiveOriginsCache;

        protected PackageReferenceProject(
            string projectName,
            string projectUniqueName,
            string projectFullPath)
        {
            ProjectName = projectName;
            ProjectUniqueName = projectUniqueName;
            ProjectFullPath = projectFullPath;
        }

        public override async Task<string> GetAssetsFilePathAsync()
        {
            return await GetAssetsFilePathAsync(shouldThrow: true);
        }

        public override async Task<string> GetAssetsFilePathOrNullAsync()
        {
            return await GetAssetsFilePathAsync(shouldThrow: false);
        }

        protected abstract Task<string> GetAssetsFilePathAsync(bool shouldThrow);

        public override string ProjectName { get; }
        protected string ProjectUniqueName { get; }
        protected string ProjectFullPath { get; }

        public override async Task<IReadOnlyList<PackageSpec>> GetPackageSpecsAsync(DependencyGraphCacheContext context)
        {
            (IReadOnlyList<PackageSpec> dgSpec, IReadOnlyList<IAssetsLogMessage> _) = await GetPackageSpecsAndAdditionalMessagesAsync(context);
            return dgSpec;
        }

        public abstract Task<ProjectPackages> GetInstalledAndTransitivePackagesAsync(CancellationToken token);

        private protected IEnumerable<PackageReference> GetPackageReferences(IEnumerable<LibraryDependency> libraries, NuGetFramework targetFramework, Dictionary<string, ProjectInstalledPackage> installedPackages, IList<LockFileTarget> targets)
        {
            return libraries
                .Where(library => library.LibraryRange.TypeConstraint == LibraryDependencyTarget.Package)
                .Select(library => new BuildIntegratedPackageReference(library, targetFramework, GetPackageReferenceUtility.UpdateResolvedVersion(library, targetFramework, targets, installedPackages)));
        }

        private protected IReadOnlyList<PackageReference> GetTransitivePackageReferences(NuGetFramework targetFramework, Dictionary<string, ProjectInstalledPackage> installedPackages, Dictionary<string, ProjectInstalledPackage> transitivePackages, IList<LockFileTarget> targets)
        {
            // If the assets files has not been updated, return the cached transitive packages
            if (targets == null)
            {
                return transitivePackages
                    .Select(package => new PackageReference(package.Value.InstalledPackage, targetFramework))
                    .ToList();
            }
            else
            {
                return targets
                    .SelectMany(target => target.Libraries)
                    .Where(library => library.Type == LibraryType.Package)
                    .SelectMany(library => GetPackageReferenceUtility.UpdateTransitiveDependencies(library, targetFramework, targets, installedPackages, transitivePackages))
                    .Select(packageIdentity => new PackageReference(packageIdentity, targetFramework))
                    .ToList();
            }
        }

        /// <summary>
        /// Return all targets (dependency graph) found in project.assets.json file
        /// </summary>
        /// <param name="token">Cancellation token</param>
        /// <returns>A 2-tuple with:
        ///  <list type="bullet">
        ///  <item>
        ///    <term>TargetsList</term>
        ///    <description>A list, one element for each framework restored, or <c>null</c> if project.assets.json file is not found</description>
        ///  </item>
        ///  <item>
        ///    <term>IsCacheHit</term>
        ///    <description>Indicates if target list was retrieved from cache</description>
        ///  </item>
        ///  </list>
        /// </returns>
        /// <remarks>Projects need to be NuGet-restored before calling this function</remarks>
        internal async Task<(IList<LockFileTarget> TargetsList, bool IsCacheHit)> GetFullRestoreGraphAsync(CancellationToken token)
        {
            token.ThrowIfCancellationRequested();

            string assetsFilePath = await GetAssetsFilePathAsync();
            var fileInfo = new FileInfo(assetsFilePath);
            IList<LockFileTarget> lastPackageSpec = null;
            bool cacheHit = _lastLockFileTargets != null ? _lastLockFileTargets.TryGetTarget(out lastPackageSpec) : false;

            (IList<LockFileTarget> TargetsList, bool IsCacheHit) returnValue = (null, false);

            if ((fileInfo.Exists && fileInfo.LastWriteTimeUtc > _lastTimeAssetsModified) || !cacheHit)
            {
                if (fileInfo.Exists)
                {
                    await TaskScheduler.Default;
                    LockFile lockFile = LockFileUtilities.GetLockFile(assetsFilePath, NullLogger.Instance);

                    returnValue.TargetsList = lockFile?.Targets;
                }

                _lastTimeAssetsModified = fileInfo.LastWriteTimeUtc;
                _lastLockFileTargets = new WeakReference<IList<LockFileTarget>>(returnValue.TargetsList);
            }
            else if (cacheHit && lastPackageSpec != null)
            {
                returnValue.IsCacheHit = true;
                returnValue.TargetsList = lastPackageSpec;
            }

            return returnValue;
        }
    }
}
